public protocol NOSTR_filter {

	associatedtype NOSTR_event_kind:Hashable, Equatable, Comparable, SignedInteger
	associatedtype NOSTR_filter_date_TYPE:NOSTR_date
	
	/// event uids to filter by
	var uids:Set<Event.UID>? { get }
	/// event kinds to filter by
	var kinds:Set<NOSTR_event_kind>? { get }
	/// retruned events will be limited to those that follow this date
	var since:Date? { get }
	/// returned events will be limited to those that precede this date
	var until:Date? { get }
	/// limit the number of events returned
	var limit:UInt32? { get }
	/// returned events must be authored by one of these public keys
	var authors:Set<nostr.PublicKey>? { get }
}