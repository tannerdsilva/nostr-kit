import NIO


extension Relay {

	/// this caps off the inbound channel pipeline as a means of firing off handlers and events for objects that were not handled upstream.
	internal final class Catcher:ChannelInboundHandler {
		typealias OKHandler = (String, Date) -> Void

		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-catcher", logLevel:.info)
		#endif

	    typealias InboundIn = Message

		/// publishing structs that are currently waiting for an ok response.
		var activePublishes:[Event.UID:Publishing] = [:]

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
			let message = self.unwrapInboundIn(data)

			#if DEBUG
			self.logger.trace("got read info.")
			#endif

			switch message {
				case .ok(let subID, let date, let event):
					if let publishing = self.activePublishes[subID] {
						#if DEBUG
						self.logger.info("got 'ok' publishing event uid: \(subID)")
						#endif
						publishing.promise.succeed(Date())
						self.activePublishes.removeValue(forKey:subID)
					}
				default:
				break;
			}
		}

		internal func addPublishingStruct(_ publishing:Publishing, for evUID:Event.UID, channel:Channel) -> EventLoopFuture<Void> {
			channel.eventLoop.submit {
				#if DEBUG
				self.logger.debug("adding publishing struct for event uid: \(evUID)")
				#endif
				self.activePublishes[evUID] = publishing
			}
		}
	}
}