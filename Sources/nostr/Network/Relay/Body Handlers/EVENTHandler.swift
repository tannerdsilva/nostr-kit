import NIO
import Logging

extension Relay {
	internal class EVENTHandler:NOSTR_frame_handler {
		private enum EventOrToggle {
			/// an event that is to be sent to the consumer
			case event(any NOSTR_event_signed)
			/// a toggle event that flips the EOSE state
			case toggle
		}

		/// an error that is thrown when the subscription ID is not found
		internal struct SubscriptionIDNotFound:Swift.Error {
			/// the subscription ID that was not found
			internal let sid:String
		}
		
		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-handler:EVENT", logLevel:.debug)
		#endif

		/// the active subscriptions that are being handled.
		var activeSubscriptions:Set<String> = []
		/// the subscriptions that the client has registered with the relay.
		/// - key: subscription ID
		/// - value: the subscription instance
		internal var subscriptions:[String:any NOSTR_subscription] = [:]
		/// the various EOSE states of the subscriptions
		/// - key: subscription ID
		/// - value: whether or not the subscription has received an EOSE frame
		internal var subscriptions_isEOSE:[String:Bool] = [:]
		/// the pending events for the subscriptions
		/// - key: subscription ID
		/// - value: an array containing a stream of events, representing either an event itself, or a toggle event that flips the EOSE state
		private var subscriptions_pending:[String:[EventOrToggle]] = [:]

		/// pertaining to the rate-limiting timer
		internal var scheduledFlush:Scheduled<Void>? = nil

		/// how much time should pass before the EVENT frame handler flushes the pending events
		private let rateLimitTime:TimeAmount

		/// initialize the EVENT frame handler with the given configuration.
		/// - Parameters:
		///   - configuration: the client configuration that is being used
		///   - eoseHandler: the EOSE frame handler that is being used.
		/// - NOTE: since this EVENT frame handler takes the EOSE frame handler as an initialization parameter, that means it handles any requirements or needs around this handler internally.
		init(configuration:Relay.Client.Configuration, eoseHandler:EOSEHandler) {
			self.rateLimitTime = configuration.eventHoldTime
		}

		/// registers the subscription with the EVENT frame handler
		/// - WARNING: MUST be called within the event loop
		internal func registerSubscription<S>(_ subscription:S) where S:NOSTR_subscription {
			let newSID = subscription.NOSTR_subscription_sid
			activeSubscriptions.update(with:newSID)
			subscriptions[newSID] = subscription
			subscriptions_isEOSE[newSID] = false
			subscriptions_pending[newSID] = []
			
			#if DEBUG
			logger.trace("registered subscription '\(newSID)'.")
			#endif
		}

		/// deregisters the subscription with the EVENT frame handler
		/// MUST be called within the event loop
		internal func deregisterSubscription<D>(_ subscription:D) where D:NOSTR_subscription {
			activeSubscriptions.remove(subscription.NOSTR_subscription_sid)
			subscriptions[subscription.NOSTR_subscription_sid] = nil
			subscriptions_isEOSE[subscription.NOSTR_subscription_sid] = nil
			subscriptions_pending[subscription.NOSTR_subscription_sid] = nil
			
			#if DEBUG
			logger.trace("deregistered subscription '\(subscription.NOSTR_subscription_sid)'.")
			#endif
		}

		/// MUST be called within the event loop
		internal func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context: NIOCore.ChannelHandlerContext) throws {
			// capture the SID for this event
			let decodeSID = try uk.decode(String.self)

			// verify that this SID is accounted for
			guard activeSubscriptions.contains(decodeSID) else {
				#if DEBUG
				logger.notice("got anonymous event match for subscription ID '\(decodeSID)'.")
				#endif
				throw SubscriptionIDNotFound(sid: decodeSID)
			}
			
			let getSub = subscriptions[decodeSID]!
			let getEvent = try getSub.NOSTR_subscription_decode_event(&uk)
			var eventsPendingList = subscriptions_pending[getSub.NOSTR_subscription_sid]!
			eventsPendingList.append(.event(getEvent))
			subscriptions_pending[getSub.NOSTR_subscription_sid] = eventsPendingList

			if scheduledFlush == nil {
				scheduledFlush = context.eventLoop.scheduleTask(in:rateLimitTime) { [self] in
					self.flushPending()
				}
			}
		}

		/// flushes all of the pending events 
		internal func flushPending() {
			
		}
	}
}