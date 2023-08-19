import NIO

#if DEBUG
import Logging
#endif

extension Relay {
	internal class EVENTHandler:NOSTR_frame_handler {
		/// an error that is thrown when the subscription ID is not found
		internal struct SubscriptionIDNotFound:Swift.Error {
			/// the subscription ID that was not found
			internal let sid:String
		}
		
		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-handler:EVENT", logLevel:.debug)
		#endif

		/// the active subscriptions that are being handled.
		private var activeSubscriptions:Set<String>
		/// the active subscriptions and their underlying instances that are being handled.
		private var subscriptions:[String:any NOSTR_subscription]
		/// tracks the EOSE state for each subscription
		private var subscription_hasReachedEOSE:[String:Bool]
		/// pending events that are waiting to be sent downstream.
		private var subscriptions_pending:[String:[any NOSTR_event_signed]]
		/// continuations for subscriptions that are pertaining to stored events.
		private var subscription_storedCont:[String:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation]
		/// continuations for subscriptions that are pertaining to events that arrive after the EOSE.
		private var subscription_streamedCont:[String:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation]

		/// pertaining to the rate-limiting timer
		private var scheduledFlush:Scheduled<Void>? = nil

		/// how much time should pass before the EVENT frame handler flushes the pending events
		private let rateLimitTime:TimeAmount

		/// hander for the EOSE frame
		private let eoseHandler:EOSEHandler

		/// initialize the EVENT frame handler with the given configuration.
		/// - parameters:
		///   - configuration: the client configuration that is being used
		///   - eoseHandler: the EOSE frame handler that is being used.
		/// - NOTE: since this EVENT frame handler takes the EOSE frame handler as an initialization parameter, that means it handles any procedural requirements or needs around this handler internally.
		init(configuration:Relay.Client.Configuration, eoseHandler:EOSEHandler) {
			self.rateLimitTime = configuration.eventHoldTime
			self.eoseHandler = eoseHandler
			self.activeSubscriptions = Set<String>()
			self.subscriptions = [String:any NOSTR_subscription]()
			self.subscription_hasReachedEOSE = [String:Bool]()
			self.subscriptions_pending = [String:[any NOSTR_event_signed]]()
			self.subscription_storedCont = [String:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation]()
			self.subscription_streamedCont = [String:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation]()
		}

		/// registers a stored subscription continuation for the EVENT frame handler.
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for registering the subscription immediately after the async streams are registered.
		internal func registerStored(subscription:String, continuation:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation) {
			self.subscription_storedCont[subscription] = continuation
		}

		/// registers a streamed subscription continuation for the EVENT frame handler.
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for registering the subscription immediately after the async streams are registered.
		internal func registerStreamed(subscription:String, continuation:AsyncThrowingStream<[any NOSTR_event_signed], Swift.Error>.Continuation) {
			self.subscription_streamedCont[subscription] = continuation
		}

		/// registers the subscription with the EVENT frame handler
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for registering the asyncstream continuations before calling this function.
		internal func registerSubscription<S>(_ subscription:S) where S:NOSTR_subscription {
			let newSID = subscription.NOSTR_subscription_sid
			activeSubscriptions.update(with:newSID)
			subscriptions[newSID] = subscription
			subscription_hasReachedEOSE[newSID] = false
			subscriptions_pending[newSID] = []

			eoseHandler.registerEOSEAction(newSID) { [weak self] sid in
				// no need for guard let self here because of how the EOSE handler works and the deinit function
				guard self!.activeSubscriptions.contains(sid) else { return }
				guard self!.subscription_hasReachedEOSE.updateValue(true, forKey:sid)! == false else { return }
				let getEvents = self!.subscriptions_pending.updateValue([], forKey:sid)!
				let storedCont = self!.subscription_storedCont[sid]!
				if getEvents.count > 0 {
					storedCont.yield(getEvents)
				}
				storedCont.finish()
				self!.subscription_storedCont[sid] = nil
				self!.subscription_hasReachedEOSE[sid] = true
			}

			#if DEBUG
			logger.trace("registered subscription '\(newSID)'.")
			if self.subscription_storedCont[newSID] == nil || self.subscription_streamedCont[newSID] == nil {
				logger.critical("you must register asyncstreams for stored and streamed events before calling `registerSubscription<S>`")
			}
			#endif
		}

		/// deregisters a stored subscription continuation for the EVENT frame handler.
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for deregistering the subscription immediately after the async streams are deregistered.
		internal func deregisterStreamed(subscription:String) {
			self.subscription_streamedCont[subscription] = nil
		}

		/// deregisters a streamed subscription continuation for the EVENT frame handler.
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for deregistering the subscription immediately after the async streams are deregistered.
		internal func deregisterStored(subscription:String) {
			self.subscription_storedCont[subscription] = nil
		}

		/// deregisters the subscription with the EVENT frame handler
		/// - WARNING: MUST be called within the event loop
		/// - WARNING: caller of this function is responsible for deregistering the asyncstream continuations before calling this function.
		internal func deregisterSubscription<D>(_ subscription:D) where D:NOSTR_subscription {
			let sid = subscription.NOSTR_subscription_sid
			guard activeSubscriptions.remove(sid) != nil else { return }
			self.subscriptions.removeValue(forKey:sid)
			let getEvents = self.subscriptions_pending.removeValue(forKey:sid)!
			switch self.subscription_hasReachedEOSE.removeValue(forKey:sid)! {
				case true:
					// finish just the streamed continuation
					let streamedCont = self.subscription_streamedCont.removeValue(forKey:sid)!
					if getEvents.count > 0 {
						streamedCont.yield(getEvents)
					}
					streamedCont.finish()
				case false:
					// finish both the streamed and stored continuations
					let storedCont = self.subscription_storedCont.removeValue(forKey:sid)!
					if getEvents.count > 0 {
						storedCont.yield(getEvents)
					}
					storedCont.finish()

			}
			subscription_hasReachedEOSE[subscription.NOSTR_subscription_sid] = nil
			
			#if DEBUG
			logger.trace("deregistered subscription '\(subscription.NOSTR_subscription_sid)'.")
			if self.subscription_storedCont[subscription.NOSTR_subscription_sid] == nil || self.subscription_streamedCont[subscription.NOSTR_subscription_sid] == nil {
				logger.critical("you must deregister asyncstreams for stored and streamed events before calling `deregisterSubscription<D>`")
			}
			#endif
		}

		/// MUST be called within the event loop
		internal func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:NIOCore.ChannelHandlerContext) throws {
			// capture the SID for this event
			let decodeSID = try uk.decode(String.self)

			// verify that this SID is accounted for
			guard activeSubscriptions.contains(decodeSID) else {
				#if DEBUG
				logger.notice("got event match for anonymous subscription ID '\(decodeSID)'.")
				#endif
				throw SubscriptionIDNotFound(sid: decodeSID)
			}
			
			let getSub = subscriptions[decodeSID]!
			let getEvent = try getSub.NOSTR_subscription_decode_event(&uk)
			var eventsPendingList = subscriptions_pending[getSub.NOSTR_subscription_sid]!
			eventsPendingList.append(getEvent)
			subscriptions_pending[getSub.NOSTR_subscription_sid] = eventsPendingList

			if scheduledFlush == nil {
				scheduledFlush = context.eventLoop.scheduleTask(in:rateLimitTime) { [self] in
					self.flushPending()
				}
			}
		}

		deinit {
			for curSub in self.activeSubscriptions {
				self.eoseHandler.deregisterEOSEAction(curSub)
			}
		}
	}
}