// (c) tanner silva 2023. all rights reserved.

/// standard nostr relay filter.
/// - compliant with `NOSTR_filter` protocol
public struct Filter {

	/// event uids to filter by
	public var uids:Set<Event.Signed.UID>?
	/// event kinds to filter by
	public var kinds:Set<UInt64>?
	/// retruned events will be limited to those that follow this date
	public var since:Date?
	/// returned events will be limited to those that precede this date
	public var until:Date?
	/// limit the number of events returned
	public var limit:UInt32?
	/// returned events must be authored by one of these public keys
	public var authors:Set<nostr.PublicKey>?
	/// the tags associated with this filter
	public var tags:[Character:[any NOSTR_tag_index]]?

	/// create a new filter
	public init(
		uids:Set<Event.Signed.UID>? = nil,
		kinds:Set<UInt64>? = nil,
		since:Date? = nil, until:Date? = nil,
		limit:UInt32? = nil,
		authors:Set<nostr.PublicKey>? = nil
	) {
		self.uids = uids
		self.kinds = kinds
		self.since = since
		self.until = until
		self.limit = limit
		self.authors = authors
	}
}

// implimentation of the NOSTR_filter protocol within the Filter struct
extension Filter:NOSTR_filter {
    public init(uids: Set<Event.Signed.UID>?, kinds: Set<UInt64>?, since: Date?, until: Date?, limit: UInt32?, authors: Set<PublicKey>?, genericTags: [Character : [any NOSTR_tag_index]]?) {
        self.uids = uids
		self.kinds = kinds
		self.since = since
		self.until = until
		self.limit = limit
		self.authors = authors
		self.tags = genericTags
    }

	public var genericTags: [Character:[any NOSTR_tag_index]]? {
		return self.tags
	}

	public typealias NOSTR_filter_event_TYPE = nostr.Event.Signed

	public var NOSTR_filter_uids:Set<Event.Signed.UID>? {
		return self.uids
	}
	public var NOSTR_filter_kinds:Set<UInt64>? {
		return self.kinds
	}
	public var NOSTR_filter_since:Date? {
		return self.since
	}
	public var NOSTR_filter_until:Date? {
		return self.until
	}
	public var NOSTR_filter_limit:UInt32? {
		return self.limit
	}
	public var NOSTR_filter_authors:Set<nostr.PublicKey>? {
		return self.authors
	}
}

extension nostr.Filter:Hashable, Equatable {
	public static func == (lhs:Filter, rhs:Filter) -> Bool {
		return lhs.uids == rhs.uids
			&& lhs.kinds == rhs.kinds
			&& lhs.since == rhs.since
			&& lhs.until == rhs.until
			&& lhs.authors == rhs.authors
			&& lhs.limit == rhs.limit
	}
	public func hash(into hasher:inout Hasher) {
		hasher.combine(uids)
		hasher.combine(kinds)
		hasher.combine(since)
		hasher.combine(until)
		hasher.combine(authors)
		hasher.combine(limit)
	}
}