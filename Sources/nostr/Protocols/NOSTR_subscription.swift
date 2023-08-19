// (c) tanner silva 2023. all rights reserved.

/// a protocol for expressing a type that can handle the inbound events from a subscription.
/// by implementing this type, you are committed to operating in this basic fashion.
public protocol NOSTR_subscription_consumer<NOSTR_subscription_TYPE> {
	/// the type of subscription that this consumer is handling
	associatedtype NOSTR_subscription_TYPE:NOSTR_subscription

	/// the async stream for handling the stored events.
	/// - written by external actors, read by the type that conforms to this protocol.
	var NOSTR_subscription_consumer_store:AsyncThrowingStream<[NOSTR_subscription_TYPE.NOSTR_subscription_event_TYPE], Swift.Error> { get set }
	
	/// the async stream for handling the streamed events.
	/// - written by external actors, read by the type that conforms to this protocol.
	var NOSTR_subscription_consumer_stream:AsyncThrowingStream<[NOSTR_subscription_TYPE.NOSTR_subscription_event_TYPE], Swift.Error> { get set }

	/// the task that handles the stored events. the type will assign this when the `launchConsumerTask()` function is called.
	var NOSTR_subscription_consumer_task:Task<Void, Swift.Error>? { get }
}

public protocol NOSTR_subscription:NOSTR_frame_encodable {
	associatedtype NOSTR_subscription_event_TYPE:NOSTR_event_signed

	/// the subscription id
	var NOSTR_subscription_sid:String { get }

	/// the filters associated with this subscription
	var NOSTR_subscription_filters:[any NOSTR_filter] { get }
}

// default implementation for NOSTR_frame
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