// (c) tanner silva 2023. all rights reserved.

import RAW

extension nostr.Relay {
	public struct Subscription<C:NOSTR_subscription_consumer>:NOSTR_subscription where C.NOSTR_subscription_event_TYPE == nostr.Event.Signed {
	    public typealias NOSTR_subscription_event_TYPE = C.NOSTR_subscription_event_TYPE

		public let NOSTR_subscription_sid:String
		public let NOSTR_subscription_filters:[any NOSTR_filter<C.NOSTR_subscription_event_TYPE>]	    
		public let NOSTR_subscription_consumer:C

		init(consumer:C, filters:[any NOSTR_filter<C.NOSTR_subscription_event_TYPE>]) {
			self.NOSTR_subscription_consumer = consumer
			self.NOSTR_subscription_filters = filters
			var buildArr = Array<UInt8>()
			var i = 0
			while i < 12 {
				buildArr.append(UInt8.random(in:0...255))
				i += 1
			}
			self.NOSTR_subscription_sid = buildArr.asRAW_val({
				return Hex.encode($0)
			})
		}
	}
}