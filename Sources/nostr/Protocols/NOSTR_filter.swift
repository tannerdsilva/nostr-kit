// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_filter<NOSTR_filter_event_TYPE> {
	associatedtype NOSTR_filter_event_TYPE:NOSTR_event_signed

	/// event uids to filter by
	var uids:Set<Event.Signed.UID>? { get }
	/// event kinds to filter by
	var kinds:Set<NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE>? { get }
	/// must be newer than this time to pass
	var since:NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE? { get }
	/// must be older than this time to pass
	var until:NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE? { get }
	/// limit the number of events returned
	var limit:UInt32? { get }
	/// returned events must be authored by one of these public keys
	var authors:Set<nostr.PublicKey>? { get }

	/// determines if the given event matches the filter (requires that the event and filter events are of the same kind type)
	func matches<E>(_ event:E) -> Bool where E:NOSTR_event_signed, E.NOSTR_event_kind_TYPE == NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE
	/// returns true if the filter is empty (contains no criteria)
	func isEmpty() -> Bool
}

extension NOSTR_filter {
	func matches<E>(_ event:E) -> Bool where E:NOSTR_event_signed, E.NOSTR_event_kind_TYPE == NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE {
		if let uids = self.uids {
			if uids.contains(event.uid) {
				return true
			}
		}
		if let kinds = self.kinds {
			if kinds.contains(event.kind) {
				return true
			}
		}
		if let since = self.since {
			if event.date.NOSTR_date_unixInterval > since.NOSTR_date_unixInterval {
				return true
			}
		}
		if let until = self.until {
			if event.date.NOSTR_date_unixInterval < until.NOSTR_date_unixInterval {
				return true
			}
		}
		if let authors = self.authors {
			if authors.contains(event.author) {
				return true
			}
		}
		return false
	}
}