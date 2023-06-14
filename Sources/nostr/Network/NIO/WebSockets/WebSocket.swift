import NIOCore
import NIOWebSocket

import struct NIOHTTP1.HTTPHeaders
import typealias NIOHTTP1.NIOHTTPClientUpgradeConfiguration

import NIOPosix
import ExtrasBase64

import Logging

import struct NIOSSL.TLSConfiguration
import class NIOSSL.NIOSSLContext
import struct NIOSSL.NIOSSLClientTLSProvider
import struct NIOCore.NIOInsecureNoTLS

public struct WebSocket {
	/// the URL type for WebSockets
	public typealias URL = Relay.URL
	internal static let logger = makeDefaultLogger(label:"net-websocket", logLevel:.debug)
}

extension WebSocket {
	public struct Configuration {
		/// contains the timeout parameters for the relay connection
		public struct Timeouts {
			/// how much time is allowed to pass as the client attempts to establish a TCP connection to the relay?
			public var tcpConnectionTimeout:TimeAmount = .seconds(5)
			/// how much time is allowed up pass as the client attempts to upgrade the connection to a WebSocket?
			public var websocketUpgradeTimeout:TimeAmount = .seconds(10)
			/// initialize a `Timeouts` struct with default values.
			public init() {}
		}

		/// the maximum frame size for the websocket connection
		public var maxFrameSize:Int

		/// the tls configuration for this relay
		public var tlsConfiguration:TLSConfiguration

		/// the timeouts for this relay
		public var timeouts:Timeouts

		public init(maxFrameSize:Int = 1 << 20, tlsConfiguration:TLSConfiguration = TLSConfiguration.makeClientConfiguration(), timeouts:Timeouts = Timeouts()) {
			self.maxFrameSize = maxFrameSize
			self.tlsConfiguration = tlsConfiguration
			self.timeouts = timeouts
		}
	}
}
public extension WebSocket {
	/// bootstrap a websocket connection
	internal static func createBootstrap(url:URL.Split, headers:HTTPHeaders = [:], configuration: Configuration, on eventLoop:EventLoop) throws -> NIOClientTCPBootstrap {
		let cb = ClientBootstrap(validatingGroup:eventLoop)
		if cb != nil {
			Self.logger.info("initiating connection to '\(url)'.", metadata:["using_tls": "\(url.tlsRequired)"])
			let bootstrap: NIOClientTCPBootstrap
			if url.tlsRequired {
				let sslContext = try NIOSSLContext(configuration:configuration.tlsConfiguration)
				let tlsProvider = try NIOSSLClientTLSProvider<ClientBootstrap>(context:sslContext, serverHostname:url.host)
				bootstrap = NIOClientTCPBootstrap(cb!, tls:tlsProvider)
				bootstrap.enableTLS()
				Self.logger.debug("successfully configured connection for TLS.")
			} else {
				bootstrap = NIOClientTCPBootstrap(cb!, tls:NIOInsecureNoTLS())
			}
			return bootstrap
		} else {
			preconditionFailure("failed to create client bootstrap")
		}
	}
	
	internal static func setupChannelForWebScokets(url:URL, headers:HTTPHeaders = [:], channel:Channel, wsPromise:EventLoopPromise<WebSocket.Handler>, on eventLoop:EventLoop, configuration:Configuration) -> EventLoopFuture<Void> {
		// this is the promise of the HTTP to WebSocket upgrade. if the connection upgrades, this succeeds. if it fails, the failure is passed.
		let upgradePromise = eventLoop.makePromise(of: Void.self)
		upgradePromise.futureResult.cascadeFailure(to: wsPromise)
		
		// create a random key for the upgrade request
		let requestKey = (0..<16).map { _ in UInt8.random(in: .min ..< .max) }
		let base64Key = String(base64Encoding:requestKey, options:[])

		// build the initial request writer.
		let initialRequestWriter: WebSocket.InitialRequestWriter
		do {
			initialRequestWriter = try WebSocket.InitialRequestWriter(url:url)
		} catch let error {
			upgradePromise.fail(error)
			return upgradePromise.futureResult
		}

		// build the websocket upgrader.
		let websocketUpgrader = WebSocket.Upgrader(requestKey:base64Key, maxFrameSize:1 << 20, upgradePromise:upgradePromise) { (channel, _) -> EventLoopFuture<Void> in
			// upgrade successful. build the nostr data channel.
			// the return value of this function will be used as an indicator of how long the inbound data should be buffered for (the buffer will be released after the promise is fufilled)
			var upgradePromise:EventLoopFuture<Void>

			// start with the websocket handler.
			let webSocketHandler = WebSocket.Handler(url:url)
			upgradePromise = channel.pipeline.addHandler(webSocketHandler)

			return upgradePromise
		}

		let config = NIOHTTPClientUpgradeConfiguration(upgraders:[websocketUpgrader], completionHandler: { _ in
			// the upgrade succeeded. remove the initial request writer.
			channel.pipeline.removeHandler(initialRequestWriter, promise:nil)
		})

		// the upgrade needs to timeout if it takes too long. 
		let upgradeTimeoutTask = eventLoop.scheduleTask(in:configuration.timeouts.websocketUpgradeTimeout) {
			upgradePromise.fail(Error.websocketUpgradeFailure)
		}

		// add the upgrade and initial request write handlers.
		return channel.pipeline.addHTTPClientHandlers(leftOverBytesStrategy:.forwardBytes, withClientUpgrade:config).flatMap {
			// the HTTP client handlers were added. now add the initial request writer.
			channel.pipeline.addHandler(initialRequestWriter)
		}.always { _ in
			upgradeTimeoutTask.cancel()
		}
	}
}