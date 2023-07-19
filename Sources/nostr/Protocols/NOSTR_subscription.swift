// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_subscription {
	/// the event type that is associated with this subscription
	associatedtype NOSTR_subscription_event_TYPE:NOSTR_event_signed

	/// the subscription id
	var NOSTR_subscription_sid:String { get }

	/// the filters associated with this subscription
	var NOSTR_subscription_filters:[any NOSTR_filter] { get }
}

extension NOSTR_subscription {
	internal func NOSTR_subscription_decode_event(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_subscription_event_TYPE {
		return try uk.decode(NOSTR_subscription_event_TYPE.self)
	}
}