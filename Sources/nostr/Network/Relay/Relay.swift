// (c) tanner silva 2023. all rights reserved.

import NIOCore

import struct NIOHTTP1.HTTPHeaders
import var NIOPosix.IPPROTO_TCP
import var NIOPosix.TCP_NODELAY

public struct Relay {

	#if DEBUG
	internal static let logger = makeDefaultLogger(label:"nostr-net:relay", logLevel:.debug)
	#endif

	/// the url for the relay.
	public let url:URL

	/// the channel that is associated with this relay.
	internal let channel:Channel

	/// the relay handler. this is the primary interface for general purpose 
	internal let handler:Relay.Handler
	internal let okHandler:OKHandler
	internal let eventHandler:EVENTHandler
	internal let catcher:Relay.Catcher

	/// the internal initializer for a relay.
	internal init(url:URL, channel:Channel, handler:Relay.Handler, catcher:Relay.Catcher, eventHandler:EVENTHandler, okHandler:OKHandler) {
		self.url = url
		self.channel = channel
		self.handler = handler
		self.eventHandler = eventHandler
		self.okHandler = handler.okHandler
		self.catcher = catcher
	}

	/// writes a pre-signed event to the remote peer.
	/// - parameters:
	/// 	- event: the signed event to post
	/// - returns: an EventLoopFuture that will eventually return the date that the event was confirmed to be posted, or a failure if unsuccessful.
	public func write<E>(event:E) -> EventLoopFuture<Date> where E:NOSTR_event_signed {

		// the promise that ties to the NIP-20 response for the published event
		let returnPromise = self.handler.okHandler.createNIP20Promise(for:event.uid)

		// the promise that ties to the write operation
		let writePromise = self.channel.eventLoop.makePromise(of:Void.self)
		writePromise.futureResult.whenComplete {
			switch $0 {
				case .success(_):
					#if DEBUG
					Self.logger.trace("successfully wrote event to relay.", metadata:["event_uid": "\(event.uid.description.prefix(8))"])
					#endif

				case .failure(let err):
					#if DEBUG
					Self.logger.error("failed to write event to relay.", metadata:["error": "\(err)", "event_uid": "\(event.uid.description.prefix(8))"])
					#endif
			}
		}
		writePromise.futureResult.cascadeFailure(to:returnPromise)
		#if DEBUG
		Self.logger.trace("writing event to relay.", metadata:["event_uid": "\(event.uid.description.prefix(8))"])
		#endif
		self.channel.write(event.NOSTR_frame_encode(), promise:writePromise)
		return returnPromise.futureResult
	}

	public func subscribe<S>(_ subscription:S, using bufferingPolicy:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation.BufferingPolicy = .bufferingNewest(64)) -> EventLoopFuture<nostr.Relay.Subscription> where S:NOSTR_subscription {
		return channel.eventLoop.submit({
			let makeStoredStream = AsyncThrowingStream([any NOSTR_event_signed].self, bufferingPolicy:bufferingPolicy) { continuation in
				return self.eventHandler.registerStored(subscription:subscription.NOSTR_subscription_sid, continuation:continuation)
			}
			let makeStream = AsyncThrowingStream([any NOSTR_event_signed].self, bufferingPolicy:bufferingPolicy) { continuation in
				return self.eventHandler.registerStreamed(subscription:subscription.NOSTR_subscription_sid, continuation:continuation)
			}
			// register the subscription in the event handler before the subscription is sent to the relay
			self.eventHandler.registerSubscription(subscription)
		})
	}
}

extension Relay {

	/// connect to a relay.
	/// - parameters:
	/// 	- url: the url to connect to.
	/// 	- headers: the headers to send with the initial request.
	/// 	- configuration: the configuration to use for the connection.
	/// 	- eventLoop: the event loop to use for the connection.
	/// - returns: a future that resolves to a `Relay` connection.
	public static func connect(url:URL, headers:HTTPHeaders = [:], configuration: Relay.Client.Configuration, on eventLoop:EventLoop) -> EventLoopFuture<Relay> {
		guard let splitURL = URL.Split(url:url) else {
			return eventLoop.makeFailedFuture(Error.invalidURL(url))
		}
		let promise = eventLoop.makePromise(of: Relay.self)
		do {
			let boot = try WebSocket.createClientBootstrap(url: splitURL, headers: headers, configuration: configuration, on: eventLoop)
			boot
				.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
				.channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
				.channelInitializer { channel in
					return WebSocket.setupChannelForWebScokets(url:url, splitURL:splitURL, channel:channel, wsPromise:promise, on:eventLoop, configuration:configuration)
				}.connectTimeout(configuration.timeouts.tcpConnectionTimeout)
				.connect(host:splitURL.host, port:Int(splitURL.port))
				.cascadeFailure(to:promise)
		} catch _ {
			promise.fail(Error.connectionBootstrapError)
		}
		return promise.futureResult
	}
}