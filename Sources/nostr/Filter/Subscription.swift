// (c) tanner silva 2023. all rights reserved.

import RAW

extension nostr.Relay {
	/// a subscription for content.
	public struct Subscription {
		/// this subscription struct is based on the `nostr.Event.Signed`
		public typealias NOSTR_subscription_event_TYPE = nostr.Event.Signed
		/// the subscription ID
		public let sid:String
		/// the filters that are being used for this subscription
		public let filters:[any NOSTR_filter<Event.Signed>]

		/// initialize a new subscription
		init(_ filters:[any NOSTR_filter<Event.Signed>], sid:String? = nil) {
			self.filters = filters
			if sid != nil {
				self.sid = sid!
			} else {
				self.sid = generateRandomSID()
			}
		}
		
		/// initialize a new subscription
		init(sid:String, _ filters:[any NOSTR_filter<Event.Signed>]) {
			self.filters = filters
			self.sid = sid
		}
	}
}

extension nostr.Relay.Subscription:NOSTR_subscription {
    public var NOSTR_subscription_filters: [any NOSTR_filter<Event.Signed>] {
        return self.filters
    }

    public var NOSTR_subscription_sid:String {
		return self.sid
    }

}

fileprivate func generateRandomSID() -> String {
	var buildArr = Array<UInt8>()
	var i = 0
	while i < 12 {
		buildArr.append(UInt8.random(in:0...255))
		i += 1
	}
	return buildArr.asRAW_val({
		return Hex.encode($0)
	})
}