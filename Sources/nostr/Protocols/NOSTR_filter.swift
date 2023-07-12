// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_filter {
	/// the kind type that is used for the event
	associatedtype NOSTR_filter_kind_TYPE:NOSTR_kind
	/// the date type that is used for the event
	associatedtype NOSTR_filter_date_TYPE:NOSTR_date
	
	/// event uids to filter by
	var uids:Set<Event.Signed.UID>? { get }

	/// event kinds to filter by
	var kinds:Set<NOSTR_filter_kind_TYPE>? { get }

	/// retruned events will be limited to those that follow this date
	var since:NOSTR_filter_date_TYPE? { get }

	/// returned events will be limited to those that precede this date
	var until:NOSTR_filter_date_TYPE? { get }

	/// limit the number of events returned
	var limit:UInt32? { get }

	/// returned events must be authored by one of these public keys
	var authors:Set<nostr.PublicKey>? { get }
}