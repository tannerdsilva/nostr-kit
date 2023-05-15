import NIOCore
import NIOHTTP1
import struct Foundation.URL

 final class RelayInitialHTTPRequestWriter: ChannelInboundHandler, RemovableChannelHandler {
	public typealias InboundIn = Never
	public typealias OutboundOut = HTTPClientRequestPart

	let urlPath:String
	let headers:HTTPHeaders

	init(url:Relay.URL, headers:HTTPHeaders = [:]) {
		self.urlPath = url.path
		self.headers = headers
	}

	public func channelActive(context:ChannelHandlerContext) {
		var requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: self.urlPath)
		requestHead.headers = self.headers
		context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)
		context.write(self.wrapOutboundOut(.end(nil)), promise: nil)
		context.flush()
	}

	public func errorCaught(context:ChannelHandlerContext, error:Error) {
		context.close(promise:nil)
	}
 }