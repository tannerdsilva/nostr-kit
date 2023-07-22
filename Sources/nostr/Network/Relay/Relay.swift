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
	internal let catcher:Relay.Catcher

	/// the internal initializer for a relay.
	internal init(url:URL, channel:Channel, handler:Relay.Handler, catcher:Relay.Catcher) {
		self.url = url
		self.channel = channel
		self.handler = handler
		self.catcher = catcher
	}

	public func write(event:nostr.Event.Signed) -> EventLoopFuture<Publishing> {
		let pubPromise = channel.eventLoop.makePromise(of:Publishing.self)
		let publishing = Publishing(relay:self.url, event:event.uid, channel:channel)
		// self.handler.ok
		self.handler.addPublishingStruct(publishing, for:event.uid).whenComplete({
			switch $0 {
				case .success():
				let writeFuture = channel.write(nostr.Relay.Message.event(.write(event)))
				pubPromise.completeWith(writeFuture.map({ publishing }))
				case .failure(let error):
				pubPromise.fail(error)
			}
		})
		return pubPromise.futureResult
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