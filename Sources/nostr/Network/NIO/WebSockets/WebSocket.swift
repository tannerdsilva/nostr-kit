// (c) tanner silva 2023. all rights reserved.

import NIOCore

import struct NIOHTTP1.HTTPHeaders
import typealias NIOHTTP1.NIOHTTPClientUpgradeConfiguration

import NIOPosix
import ExtrasBase64

import Logging

import struct NIOSSL.TLSConfiguration
import class NIOSSL.NIOSSLContext
import struct NIOSSL.NIOSSLClientTLSProvider
import struct NIOCore.NIOInsecureNoTLS

/// the primary struct for the WebSocket connection
internal struct WebSocket {
	/// the URL type for WebSocket
	internal static let logger = makeDefaultLogger(label:"net-websocket", logLevel:.debug)
}

extension WebSocket {

	/// bootstrap a websocket connection
	internal static func createClientBootstrap(url:URL.Split, headers:HTTPHeaders = [:], configuration:Relay.Client.Configuration, on eventLoop:EventLoop) throws -> NIOClientTCPBootstrap {
		let cb = ClientBootstrap(validatingGroup:eventLoop)
		if cb != nil {

			#if DEBUG
			Self.logger.info("initiating connection to '\(url.host)'.", metadata:["using_tls": "\(url.tlsRequired)"])
			#endif

			let bootstrap: NIOClientTCPBootstrap
			if url.tlsRequired {
				let sslContext = try NIOSSLContext(configuration:configuration.tlsConfiguration)
				let tlsProvider = try NIOSSLClientTLSProvider<ClientBootstrap>(context:sslContext, serverHostname:url.host)
				bootstrap = NIOClientTCPBootstrap(cb!, tls:tlsProvider)
				bootstrap.enableTLS()

				#if DEBUG
				Self.logger.trace("successfully configured connection for TLS.")
				#endif
			} else {
				bootstrap = NIOClientTCPBootstrap(cb!, tls:NIOInsecureNoTLS())
			}
			return bootstrap
		} else {
			preconditionFailure("failed to create client bootstrap")
		}
	}
	
	internal static func setupChannelForWebScokets(url:URL, splitURL:URL.Split, headers:HTTPHeaders = [:], channel:Channel, wsPromise:EventLoopPromise<Relay>, on eventLoop:EventLoop, configuration:Relay.Client.Configuration) -> EventLoopFuture<Void> {
		
		// this is the promise of the HTTP to WebSocket upgrade. if the connection upgrades, this succeeds. if it fails, the failure is passed.
		let upgradePromise = eventLoop.makePromise(of: Void.self)
		upgradePromise.futureResult.cascadeFailure(to: wsPromise)


		// light up the timeout task.
		let timeoutTask = channel.eventLoop.scheduleTask(in: configuration.timeouts.websocketUpgradeTimeout) {
			// the timeout task fired. fail the upgrade promise.
			upgradePromise.fail(Relay.Error.WebSocket.UpgradeError.upgradeTimedOut)
		}

		// create a random key for the upgrade request
		let requestKey = (0..<16).map { _ in UInt8.random(in: .min ..< .max) }
		let base64Key = String.base64Encoded(bytes:requestKey)

		// build the initial request writer.
		let initialRequestWriter = WebSocket.InitialRequestWriter(url:splitURL)

		// build the websocket upgrader.
		let websocketUpgrader = WebSocket.Upgrader(surl:splitURL, url:url, requestKey:base64Key, maxWebSocketFrameSize:configuration.limits.maxWebSocketFrameSize, upgradePromise:upgradePromise) { (channel, _) -> EventLoopFuture<Void> in
			
			// upgrade successful. build the nostr data channel.
			// the return value of this function will be used as an indicator of how long the inbound data should be buffered for (the buffer will be released after the promise is fufilled)
			var upgradePromise:EventLoopFuture<Void>
			
			// start with the websocket handler.
			let webSocketHandler = WebSocket.Handler(url:url, configuration:configuration)
			let relayHandler = Relay.Handler(url:url, configuration:configuration, )
			let catcher = Relay.Catcher()
			let relay = Relay(url:url, channel:channel, handler:relayHandler, catcher:catcher)
			upgradePromise = channel.pipeline.addHandlers([webSocketHandler, relayHandler, catcher])
			upgradePromise.whenSuccess({
				wsPromise.succeed(relay)
			})
			
			return upgradePromise
		}

		let config = NIOHTTPClientUpgradeConfiguration(upgraders:[websocketUpgrader], completionHandler: { context in
			timeoutTask.cancel()
			// the upgrade succeeded. remove the initial request writer.
			channel.pipeline.removeHandler(initialRequestWriter, promise:nil)
		})

		// add the upgrade and initial request write handlers.
		return channel.pipeline.addHTTPClientHandlers(leftOverBytesStrategy:.forwardBytes, withClientUpgrade:config).flatMap {
			// the HTTP client handlers were added. now add the initial request writer.
			channel.pipeline.addHandler(initialRequestWriter)
		}
	}
}