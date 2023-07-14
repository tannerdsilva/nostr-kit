// (c) tanner silva 2023. all rights reserved.

import NIOCore
import NIOHTTP1

extension WebSocket {

	/// writes the initial HTTP request to the channel. this is a channel handler that is removed after the request is written.
	internal final class InitialRequestWriter: ChannelInboundHandler, RemovableChannelHandler {
		typealias InboundIn = HTTPClientResponsePart
		typealias OutboundOut = HTTPClientRequestPart

		// the path of the URL to request
		internal let urlPath:String

		/// initialize with a URL.
		/// - throws: if the URL is invalid
		internal init(url:URL.Split) {
			self.urlPath = url.pathQuery
		}

		/// called when the channel becomes active.
		internal func channelActive(context:ChannelHandlerContext) {
			let promise = context.eventLoop.makePromise(of:Void.self)

			// writes the HTTP request to the channel immediately.
			let requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: self.urlPath)
			context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)
			context.write(self.wrapOutboundOut(.body(.byteBuffer(.init()))), promise:nil)
			
			context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: promise)

			promise.futureResult.whenComplete({ result in
				switch result {
					case .success():
						#if DEBUG
						WebSocket.logger.trace("wrote initial HTTP upgrade request.")
						#endif
						return
					case .failure(let error):
						#if DEBUG
						WebSocket.logger.error("failed to write initial HTTP upgrade request: \(error)")
						#endif
						context.fireErrorCaught(Relay.Error.WebSocket.UpgradeError.failedToWriteInitialRequest(error))
				}
				
			})
		}

		/// close the channel if there is an issue.
		internal func errorCaught(context:ChannelHandlerContext, error:Error) {
			context.close(promise:nil)
		}
	}
}
