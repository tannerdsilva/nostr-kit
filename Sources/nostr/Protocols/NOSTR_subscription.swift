// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_subscription_consumer<NOSTR_subscription_event_TYPE> {
	associatedtype NOSTR_subscription_event_TYPE:NOSTR_event_signed

	/// called for new events after the eose frame is received
	func NOSTR_subscription_consumer_receive_streamed_event(_ events:[NOSTR_subscription_event_TYPE])

	/// called for new events before the eose frame is received
	func NOSTR_subscription_consumer_receive_stored_event(_ events:[NOSTR_subscription_event_TYPE])

	/// called when the end of stored events is reached
	func NOSTR_subscription_consumer_receive_eose()
}

public protocol NOSTR_subscription:NOSTR_frame_encodable {
	/// the event type that is associated with this subscription
	associatedtype NOSTR_subscription_event_TYPE:NOSTR_event_signed
	/// the type of consumer that is associated with this subscription
	associatedtype NOSTR_subscription_consumer_TYPE:NOSTR_subscription_consumer<NOSTR_subscription_event_TYPE>

	/// the subscription id
	var NOSTR_subscription_sid:String { get }

	/// the filters associated with this subscription
	var NOSTR_subscription_filters:[any NOSTR_filter<NOSTR_subscription_event_TYPE>] { get }

	/// the consumer for this subscription
	var NOSTR_subscription_consumer:NOSTR_subscription_consumer_TYPE { get }
}

extension NOSTR_subscription {
	public func NOSTR_frame_encode() -> Relay.EncodingFrame {
		var buildContents:[any Codable] = [self.NOSTR_subscription_sid]
		buildContents.append(contentsOf:self.NOSTR_subscription_filters)
		return nostr.Relay.EncodingFrame(name:"REQ", contents:buildContents)
	}
}

extension NOSTR_subscription {
	/// decodes the subscriptions event type from the specified unkeyed decoding container
	internal func NOSTR_subscription_decode_event(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_subscription_event_TYPE {
		return try uk.decode(NOSTR_subscription_event_TYPE.self)
	}
}