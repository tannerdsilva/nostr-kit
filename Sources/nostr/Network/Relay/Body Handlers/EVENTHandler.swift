import NIO
import Logging

extension Relay {
	internal struct EVENTHandler:NOSTR_frame_handler {

		/// an error that is thrown when the subscription ID is not found
		internal struct SubscriptionIDNotFound:Swift.Error {
			internal let sid:String
		}
		
		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-handler:EVENT", logLevel:.debug)
		#endif

		/// the subscriptions that the client has registered with the relay
		internal var subscriptions:[String:any NOSTR_subscription] = [:]

		/// pertaining to the grouped return of events based on the configured subscription
		internal var subscriptions_pending:[String:[any NOSTR_event_signed]] = [:]
		internal var pendingCount:UInt64 = 0

		/// pertaining to the rate-limiting timer
		internal var scheduledFlush:Scheduled<Void>? = nil

		private let rateLimitTime:TimeAmount

		init(configuration:Relay.Client.Configuration) {
			self.rateLimitTime = configuration.eventHoldTime
		}

		/// MUST be called within the event loop
		internal mutating func registerSubscription<S>(_ subscription:S) where S:NOSTR_subscription {
			subscriptions[subscription.NOSTR_subscription_sid] = subscription

			#if DEBUG
			logger.trace("registered subscription '\(subscription.NOSTR_subscription_sid)'.")
			#endif
		}

		/// MUST be called within the event loop
		internal mutating func deregisterSubscription<D>(_ subscription:D) where D:NOSTR_subscription {
			subscriptions[subscription.NOSTR_subscription_sid] = nil

			#if DEBUG
			logger.trace("deregistered subscription '\(subscription.NOSTR_subscription_sid)'.")
			#endif
		}

		/// MUST be called within the event loop
		internal mutating func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context: NIOCore.ChannelHandlerContext) throws {
			guard let getSub = subscriptions[try uk.decode(String.self)] else {
				throw SubscriptionIDNotFound(sid: uk.codingPath.last!.stringValue)
			}
			let getEvent = try getSub.NOSTR_subscription_decode_event(&uk)
			if var hasEvs = subscriptions_pending[getSub.NOSTR_subscription_sid] {
				hasEvs.append(getEvent)
				subscriptions_pending[getSub.NOSTR_subscription_sid] = hasEvs
			} else {
				subscriptions_pending[getSub.NOSTR_subscription_sid] = [getEvent]
			}
			pendingCount += 1
			if scheduledFlush == nil {
				scheduledFlush = context.eventLoop.scheduleTask(in:rateLimitTime) {
					// self.flushPending()
				}
			}
		}
	}
}