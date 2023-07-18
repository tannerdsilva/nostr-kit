// (c) tanner silva 2023. all rights reserved.

import NIO

extension Relay {

	/// catches the events in the channel and groups them together so that they can be passed downstream more efficiently
	internal final class Catcher:ChannelInboundHandler {

		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-catcher", logLevel:.info)
		#endif

	    internal typealias InboundIn = Message<nostr.Event.Signed>
		internal typealias OutboundOut = Message<nostr.Event.Signed>

		// the task that is used to flush the channel.
		private var flushTask:Scheduled<Void>? = nil
		private let holdPeriod:TimeAmount

		/// consumers of various active subscriptions.
		// private var subHandlers:[String:nostr.Consumer] = [:]

		/// main initializer.
		/// - parameters:
		/// 	- holdPeriod: the amount of time subscription events are held before being dispatched downstream as a group
		init(holdPeriod:TimeAmount = .milliseconds(200)) {
			self.holdPeriod = holdPeriod
		}

		/// schedules a task to flush the events
		private func scheduleFlushTask(channel:Channel) {
			self.flushTask = channel.eventLoop.scheduleTask(in:self.holdPeriod, {
				self.flushTask = nil
			})
		}

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
				case .event(let context):
					switch context {
						case .sub(let subID, let event):
							#if DEBUG
							self.logger.trace("got write event.")
							#endif
							
							// fire channel read would happen here if there were more elements in the pipeline
						default:
							break;
					}
				default:
					break;
			}
		}
	}
}