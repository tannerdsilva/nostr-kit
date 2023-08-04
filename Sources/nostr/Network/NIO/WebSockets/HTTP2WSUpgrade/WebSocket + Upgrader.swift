// (c) tanner silva 2023. all rights reserved.

import NIOCore
import NIOHTTP1
import NIOWebSocket

import Logging

fileprivate let magicWebSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

extension WebSocket {

	/// this is the class that is used to upgrade the HTTP connection to a WebSocket connection.
	internal final class Upgrader: NIOHTTPClientProtocolUpgrader {
		#if DEBUG
		internal let logger:Logger
		#endif

		/// errors that may be throwin into an instance's `upgradePromise
		internal enum Error:Swift.Error {
			/// the part of the response that the error is concerned with
			enum ResponsePart:UInt8 {
				case httpStatus
				case websocketAcceptValue
			}
			/// a general error that is thrown when the upgrade could not be completed
			case invalidResponse(ResponsePart)

			/// a specific error that is thrown when a redirect error is encountered
			case requestRedirected(String)
		}

		/// required for NIOHTTPClientProtocolUpgrader - defines the protocol that this upgrader supports.
		internal let supportedProtocol: String = "websocket"

		/// required by NIOHTTPClientProtocolUpgrader - defines the headers that must be present in the upgrade response for the upgrade to be successful.
		/// - this is needed for certain protocols, but not for websockets, so we can leave this alone.
		internal let requiredUpgradeHeaders: [String] = []

		/// the split url that this channel is connected to
		private let surl:URL.Split
		/// request key to be assigned to the `Sec-WebSocket-Key` HTTP header.
		private let requestKey: String
		/// largest incoming `WebSocketFrame` size in bytes. This is used to set the `maxFrameSize` on the `WebSocket` channel handler upon a successful upgrade.
		private let maxWebSocketFrameSize: Int
		/// if true, adds `WebSocketProtocolErrorHandler` to the channel pipeline to catch and respond to WebSocket protocol errors.
		private let automaticErrorHandling: Bool
		/// called once the upgrade was successful or unsuccessful.
		private let upgradePromise:EventLoopPromise<Void>
		/// called once the upgrade was successful. This is the owners opportunity to add any needed handlers to the channel pipeline.
		private let upgradeInitiator:(Channel, HTTPResponseHead) -> EventLoopFuture<Void>

		/// - parameters:
		///   - host: sent to the server in the `Host` HTTP header. default value is "localhost".
		///   - requestKey: sent to the server in the `Sec-WebSocket-Key` HTTP header. Default is random request key.
		///   - maxWebSocketFrameSize: largest incoming `WebSocketFrame` size in bytes.
		///   - automaticErrorHandling: If true, adds `WebSocketProtocolErrorHandler` to the channel pipeline to catch and respond to WebSocket protocol errors. Default is true.
		///   - upgradePipelineHandler: called once the upgrade was successful
		internal init(surl:URL.Split, url:URL, requestKey:String, maxWebSocketFrameSize:Int, automaticErrorHandling: Bool = true, upgradePromise:EventLoopPromise<Void>, upgradeInitiator: @escaping (Channel, HTTPResponseHead) -> EventLoopFuture<Void>) {
			self.surl = surl
			self.requestKey = requestKey
			self.maxWebSocketFrameSize = maxWebSocketFrameSize
			self.automaticErrorHandling = automaticErrorHandling
			self.upgradePromise = upgradePromise
			self.upgradeInitiator = upgradeInitiator

			#if DEBUG
			var copyLogger = WebSocket.logger
			copyLogger[metadataKey: "url"] = "\(url)"
			self.logger = copyLogger
			self.logger.trace("instance initialized.")
			#endif
		}

		/// adds additional headers that are needed for a WebSocket upgrade request. It is important that it is done this way, as to have the "final say" in the values of these headers before they are written.
		internal func addCustom(upgradeRequestHeaders:inout HTTPHeaders) {
			upgradeRequestHeaders.replaceOrAdd(name: "Sec-WebSocket-Key", value: self.requestKey)
			upgradeRequestHeaders.replaceOrAdd(name: "Sec-WebSocket-Version", value: "13")
			// RFC 6455 requires this to be case-insensitively compared. However, many server sockets check explicitly for == "Upgrade", and SwiftNIO will (by default) send a header that is "upgrade" if not for this custom implementation with the NIOHTTPProtocolUpgrader protocol.
			upgradeRequestHeaders.replaceOrAdd(name: "Connection", value: "Upgrade")
			upgradeRequestHeaders.replaceOrAdd(name: "Upgrade", value: "websocket")
			upgradeRequestHeaders.replaceOrAdd(name: "Host", value: "\(surl.host):\(surl.port)")
			#if DEBUG
			self.logger.trace("custom headers applied to HTTP upgrade request.")
			#endif
		}

		
		/// allow or deny the upgrade based on the upgrade HTTP response headers containing the correct accept key.
		internal func shouldAllowUpgrade(upgradeResponse: HTTPResponseHead) -> Bool {
			return self._shouldAllowUpgrade(upgradeResponse: upgradeResponse)
		}
		
		/// the internal allow upgrade function. the most critical part of this code is how the result of this upgrade is handled.
		/// - if the upgrade is allowed, the `upgradePromise` is NOT fulfilled in this code.
		/// - if the upgrade is denied, the `upgradePromise` is filfilled with a FAILURE in this code.
		private func _shouldAllowUpgrade(upgradeResponse:HTTPResponseHead) -> Bool {
			// determine a basic path forward based on the HTTP response status code
			switch upgradeResponse.status {
				case .movedPermanently, .found, .seeOther, .notModified, .useProxy, .temporaryRedirect, .permanentRedirect:
					// redirect response likely
					guard let hasNewLocation = (upgradeResponse.headers["Location"].first ?? upgradeResponse.headers["location"].first) else {
						self.upgradePromise.fail(Error.invalidResponse(.httpStatus))
						return false
					}
					self.upgradePromise.fail(Error.requestRedirected(hasNewLocation))
					return false
				case .switchingProtocols:
					// this is the only path forward. lets go.
					break
				default:
					// unknown response
					self.upgradePromise.fail(Error.invalidResponse(.httpStatus))
					return false
			}

			// Validate the response key in 'Sec-WebSocket-Accept'
			let acceptValueHeader = upgradeResponse.headers["Sec-WebSocket-Accept"]
			guard acceptValueHeader.count == 1 else {
				return false
			}

			// Validate the response key in 'Sec-WebSocket-Accept'.
			var hasher = SHA1()
			hasher.update(string: self.requestKey)
			hasher.update(string: magicWebSocketGUID)
			let expectedAcceptValue = String.base64Encoded(bytes:hasher.finish())
			
			#if DEBUG
			let upgradeResult = acceptValueHeader[0] == expectedAcceptValue
			if upgradeResult == false {
				self.logger.error("failed to upgrade protocol from https to wws.", metadata: ["expectedAcceptValue": .string(expectedAcceptValue), "acceptValueHeader": .string(acceptValueHeader[0])])
			}
			self.logger.trace("evaluating upgrade result based on HTTP response. allowing upgrade: \(upgradeResult)")
			return upgradeResult
			#else
			return acceptValueHeader[0] == expectedAcceptValue
			#endif
		}

		/// called when the upgrade response has been flushed and it is safe to mutate the channel pipeline. Adds channel handlers for websocket frame encoding, decoding and errors.
		internal func upgrade(context: ChannelHandlerContext, upgradeResponse: HTTPResponseHead) -> EventLoopFuture<Void> {
			var useHandlers:[NIOCore.ChannelHandler] = [ByteToMessageHandler(WebSocketFrameDecoder(maxFrameSize:self.maxWebSocketFrameSize))]
			if self.automaticErrorHandling {
				useHandlers.append(WebSocketProtocolErrorHandler())
			}
			let upgradeFuture:EventLoopFuture<Void> = context.pipeline.addHandler(WebSocketFrameEncoder()).flatMap { [uh = useHandlers, chan = context.channel, upR = upgradeResponse, upI = self.upgradeInitiator] in
				context.pipeline.addHandlers(uh).flatMap { [ch = chan, ur = upR, ui = upI] in
					ui(ch, ur)
				}
			}
			upgradeFuture.cascade(to: self.upgradePromise)
			return upgradeFuture
		}
	}
}