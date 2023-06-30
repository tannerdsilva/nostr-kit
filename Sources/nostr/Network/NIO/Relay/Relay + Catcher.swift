import NIO


extension Relay {

	/// this caps off the inbound channel pipeline as a means of firing off handlers and events for objects that were not handled upstream.
	internal final class Catcher:ChannelInboundHandler {
		typealias OKHandler = (String, Date) -> Void

		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-catcher", logLevel:.debug)
		#endif

	    typealias InboundIn = Message

		/// publishing structs that are currently waiting for an ok response.
		var activePublishes:[nostr.Event.UID:Publishing] = [:]

		internal func handlerAdded(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.trace("added to pipeline.")
			#endif
		}

		internal func handlerRemoved(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.trace("removed from pipeline.")
			#endif
		}

		internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
			#if DEBUG
			self.logger.notice("got read info.")
			#endif
		}

		internal func addPublishingStruct(_ publishing:Publishing, forUID evUID:nostr.Event.UID, channel:Channel) {
			channel.eventLoop.execute {
				#if DEBUG
				self.logger.info("adding publishing struct for subscription id: \(evUID)")
				#endif
				self.activePublishes[evUID] = publishing
			}
		}
	}
}