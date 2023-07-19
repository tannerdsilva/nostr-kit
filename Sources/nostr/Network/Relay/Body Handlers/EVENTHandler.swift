import NIO

extension Relay {
	internal struct EVENTHandler:NOSTR_frame_handler {
		internal struct SubscriptionIDNotFound:Swift.Error {
			internal let sid:String
		}
		
		/// the subscriptions that the client has registered with the relay
		internal var subscriptions:[String:any NOSTR_subscription] = [:]

		/// pertaining to the grouped return of events based on the configured subscription
		internal var subscriptions_pending:[String:[any NOSTR_event_signed]] = [:]

		/// MUST be called within the event loop
		internal mutating func registerSubscription<S>(_ subscription:S) where S:NOSTR_subscription {
			subscriptions[subscription.NOSTR_subscription_sid] = subscription
		}

		mutating func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context: NIOCore.ChannelHandlerContext) throws {
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


		}

	}
}