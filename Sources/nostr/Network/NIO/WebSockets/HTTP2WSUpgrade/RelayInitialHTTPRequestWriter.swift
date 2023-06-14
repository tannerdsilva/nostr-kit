import NIOCore
import NIOHTTP1
import struct Foundation.URL


extension WebSocket {
	/// writes the initial HTTP request to the channel. this is a channel handler that is removed after the request is written.
	internal final class InitialRequestWriter: ChannelInboundHandler, RemovableChannelHandler {
		typealias InboundIn = Never
		typealias OutboundOut = HTTPClientRequestPart

		// the path of the URL to request
		internal let urlPath:String

		/// initialize with a URL.
		/// - throws: if the URL is invalid
		internal init(url:Relay.URL) throws {
			let splitURL = URL.Split(url:url)!
			self.urlPath = splitURL.pathQuery
		}

		/// called when the channel becomes active.
		internal func channelActive(context:ChannelHandlerContext) {
			// writes the HTTP request to the channel immediately.
			let requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: self.urlPath)
			context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)
			context.write(self.wrapOutboundOut(.end(nil)), promise: nil)
			context.flush()
			WebSocket.logger.debug("wrote initial HTTP upgrade request.")
		}

		/// close the channel if there is an issue.
		internal func errorCaught(context:ChannelHandlerContext, error:Error) {
			context.close(promise:nil)
		}
	}
}
