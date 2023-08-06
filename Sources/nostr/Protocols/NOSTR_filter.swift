// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_filter<NOSTR_filter_event_TYPE> {
	/// the underlying type that this filter is representing.
	/// - this is used to natively encode and decode the events associated with this filter.
	associatedtype NOSTR_filter_event_TYPE:NOSTR_event_signed = nostr.Event.Signed

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

	/// the generic tags (and their corresponding values) that this filter could match with
	var genericTags:[Character:[any NOSTR_tag_index]]? { get }

	/// determines if the given event matches the filter (requires that the event and filter events are of the same kind type)
	func matches<E>(_ event:E) -> Bool where E:NOSTR_event_signed, E.NOSTR_event_kind_TYPE == NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE
	/// returns true if the filter is empty (contains no criteria)
	func isEmpty() -> Bool
}

extension NOSTR_filter {
	public func matches<E>(_ event:E) -> Bool where E:NOSTR_event_signed, E.NOSTR_event_kind_TYPE == NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE {
		if self.uids != nil {
			if self.uids!.contains(event.uid) {
				return true
			}
		}
		if self.kinds != nil {
			if self.kinds!.contains(event.kind) {
				return true
			}
		}
		if self.since != nil {
			if event.date.NOSTR_date_unixInterval > self.since!.NOSTR_date_unixInterval {
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
		if genericTags != nil {
			// convert the tags into a dictionary of names and their corresponding index values
			let checkEventTags = event.tags.asNamedDictionary()
			// for each generic row that is in this event
			for (tagName, tagMatches) in genericTags! {
				// check if the event has a tag with the same name
				let checkForValues = checkEventTags[tagName.NOSTR_tag_name]
				if checkForValues != nil {
					// it does have a tag with the same name, so check if any of the values match
					for tagMatch in tagMatches {
						if checkForValues!.contains(tagMatch.NOSTR_tag_index) {
							return true
						}
					}
				}
			}
		}
		return false
	}

	/// a convenience function to check if the filter is populated with any criteria.
	public func isEmpty() -> Bool {
		return (self.uids == nil || self.uids!.count == 0) &&
				(self.kinds == nil || self.kinds!.count == 0) &&
				self.since == nil && self.until == nil &&
				(self.authors == nil || self.authors!.count == 0) &&
				self.genericTags == nil
	}
}