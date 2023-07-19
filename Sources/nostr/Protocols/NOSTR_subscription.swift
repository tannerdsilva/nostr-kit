public protocol NOSTR_subscription {
	var sid:String { get }
	var filters:[any NOSTR_filter]
}