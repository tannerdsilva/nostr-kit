import NIOCore
import NIOHTTP1
import NIOWebSocket
import CNIOSHA1

fileprivate let magicWebSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

extension WebSocket {
	/// this is the class that is used to upgrade the HTTP connection to a WebSocket connection.
	internal final class Upgrader: NIOHTTPClientProtocolUpgrader {
		#if DEBUG
		static let logger = makeDefaultLogger(label:"net-websocket-upgrader", logLevel:.debug)
		#endif

		/// errors that may be throwin into an instance's `upgradePromise
		internal enum Error:Swift.Error {
			enum ResponsePart:String {
				case httpStatus = "http status"
				case websocketAcceptValue = "websocket accept value"
			}
			/// a general error that is thrown when the upgrade could not be completed
			case invalidResponse(ResponsePart)

			/// a specific error that is thrown when a redirect error is encountered
			case requestRedirected(String)
		}

		/// required for NIOHTTPClientProtocolUpgrader - defines the protocol that this upgrader supports.
		let supportedProtocol: String = "websocket"

		/// required by NIOHTTPClientProtocolUpgrader - defines the headers that must be present in the upgrade response for the upgrade to be successful.
		/// - this is needed for certain protocols, but not for websockets, so we can leave this alone.
		let requiredUpgradeHeaders: [String] = []

		/// request key to be assigned to the `Sec-WebSocket-Key` HTTP header.
		private let requestKey: String
		/// largest incoming `WebSocketFrame` size in bytes. This is used to set the `maxFrameSize` on the `WebSocket` channel handler upon a successful upgrade.
		private let maxFrameSize: Int
		/// if true, adds `WebSocketProtocolErrorHandler` to the channel pipeline to catch and respond to WebSocket protocol errors.
		private let automaticErrorHandling: Bool
		/// called once the upgrade was successful or unsuccessful.
		private let upgradePromise:EventLoopPromise<Void>
		/// called once the upgrade was successful. This is the owners opportunity to add any needed handlers to the channel pipeline.
		private let upgradeInitiator: (Channel, HTTPResponseHead) -> EventLoopFuture<Void>

		/// - parameters:
		///   - host: sent to the server in the `Host` HTTP header. 
		///     - default is "localhost".
		///   - requestKey: sent to the server in the `Sec-WebSocket-Key` HTTP header. Default is random request key.
		///   - maxFrameSize: largest incoming `WebSocketFrame` size in bytes. 
		///     - default is 16,384 bytes.
		///   - automaticErrorHandling: If true, adds `WebSocketProtocolErrorHandler` to the channel pipeline to catch and respond to WebSocket protocol errors. Default is true.
		///   - upgradePipelineHandler: called once the upgrade was successful
		internal init(requestKey:String, maxFrameSize: Int = 1 << 20, automaticErrorHandling: Bool = true, upgradePromise:EventLoopPromise<Void>, upgradeInitiator: @escaping (Channel, HTTPResponseHead) -> EventLoopFuture<Void>) {
			precondition(requestKey != "", "The request key must contain a valid Sec-WebSocket-Key")
			precondition(maxFrameSize <= UInt32.max, "invalid overlarge max frame size")
			self.requestKey = requestKey
			self.maxFrameSize = maxFrameSize
			self.automaticErrorHandling = automaticErrorHandling
			self.upgradePromise = upgradePromise
			self.upgradeInitiator = upgradeInitiator

			#if DEBUG
			Self.logger.trace("instance initialized.")
			#endif
		}

		/// adds additional headers that are needed for a WebSocket upgrade request. It is important that it is done this way, as to have the "final say" in the values of these headers before they are written.
		internal func addCustom(upgradeRequestHeaders: inout HTTPHeaders) {
			upgradeRequestHeaders.replaceOrAdd(name: "Sec-WebSocket-Key", value: self.requestKey)
			upgradeRequestHeaders.replaceOrAdd(name: "Sec-WebSocket-Version", value: "13")
			// RFC 6455 requires this to be case-insensitively compared. However, many server sockets check explicitly for == "Upgrade", and SwiftNIO will (by default) send a header that is "upgrade" if not for this custom implementation with the NIOHTTPProtocolUpgrader protocol.
			upgradeRequestHeaders.replaceOrAdd(name: "Connection", value: "Upgrade")
			upgradeRequestHeaders.replaceOrAdd(name: "Upgrade", value: "websocket")

			#if DEBUG
			Self.logger.trace("custom headers applied to HTTP upgrade request.")
			#endif
		}

		
		/// allow or deny the upgrade based on the upgrade HTTP response headers containing the correct accept key.
		internal func shouldAllowUpgrade(upgradeResponse: HTTPResponseHead) -> Bool {
			#if DEBUG
			let captureResult = self._shouldAllowUpgrade(upgradeResponse: upgradeResponse)
			Self.logger.trace("evaluating upgrade result based on HTTP response. allowing upgrade: \(captureResult)")
			return captureResult
			#else
			return self._shouldAllowUpgrade(upgradeResponse: upgradeResponse)
			#endif
		}

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
			let expectedAcceptValue = String(base64Encoding: hasher.finish())
			
			#if DEBUG
			let upgradeResult = acceptValueHeader[0] == expectedAcceptValue
			if upgradeResult == true {
				Self.logger.debug("successfully upgraded protocol from https to wws.")
			} else {
				Self.logger.error("failed to upgrade protocol from https to wws.", metadata: ["expectedAcceptValue": .string(expectedAcceptValue), "acceptValueHeader": .string(acceptValueHeader[0])])
			}
			Self.logger.trace("evaluating upgrade result based on HTTP response. allowing upgrade: \(upgradeResult)")
			return upgradeResult
			#else
			return acceptValueHeader[0] == expectedAcceptValue
			#endif
		}

		/// called when the upgrade response has been flushed and it is safe to mutate the channel pipeline. Adds channel handlers for websocket frame encoding, decoding and errors.
		internal func upgrade(context: ChannelHandlerContext, upgradeResponse: HTTPResponseHead) -> EventLoopFuture<Void> {
			var useHandlers:[NIOCore.ChannelHandler] = [ByteToMessageHandler(WebSocketFrameDecoder(maxFrameSize:self.maxFrameSize))]
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