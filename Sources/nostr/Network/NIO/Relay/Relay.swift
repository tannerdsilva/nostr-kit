import NIOCore

import struct NIOHTTP1.HTTPHeaders
import var NIOPosix.IPPROTO_TCP
import var NIOPosix.TCP_NODELAY

public struct Relay {
	internal let handler:Relay.Handler

	internal init(handler:Relay.Handler) {
		self.handler = handler
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
		guard let splitURL = Relay.URL.Split(url:url) else {
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