// (c) tanner silva 2023. all rights reserved.

/// standard nostr relay filter.
/// - compliant with `NOSTR_filter` protocol
public struct Filter:NOSTR_filter {
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
	public var genericTags:[Character:[any NOSTR_tag_index]]?

	/// create a new filter
	public init(
		uids:Set<Event.Signed.UID>? = nil,
		kinds:Set<UInt64>? = nil,
		since:Date? = nil, until:Date? = nil,
		limit:UInt32? = nil,
		authors:Set<nostr.PublicKey>? = nil,
		genericTags:[Character:[any NOSTR_tag_index]]? = nil
	) {
		self.uids = uids
		self.kinds = kinds
		self.since = since
		self.until = until
		self.limit = limit
		self.authors = authors
	}
}

extension nostr.Filter {
	public struct Handled<NOSTR_filter_TYPE:NOSTR_filter>:NOSTR_filter_handled {
		private let baseFilter:NOSTR_filter_TYPE
		private let handlerFunction:(NOSTR_filter_TYPE.NOSTR_filter_event_TYPE) -> Void
		public init(_ filter:NOSTR_filter_TYPE, _ handler:@escaping(NOSTR_filter_TYPE.NOSTR_filter_event_TYPE) -> Void) {
			let (stored, streamed) = AsyncStream(NOSTR_filter_event_TYPE.self, { cont in
				
			})
			self.baseFilter = filter
			self.handlerFunction = handler
		}
		public func handleMatches(_ events:[any NOSTR_filter_TYPE]) {
			handlerFunction()
		}
	}
}

extension nostr.Filter.Handled {
    public var uids: Set<Event.Signed.UID>? {
        return baseFilter.uids
    }

    public var kinds: Set<NOSTR_filter_TYPE.NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE>? {
        return baseFilter.kinds
    }

    public var since:NOSTR_filter_TYPE.NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE? {
        return baseFilter.since
    }

    public var until:NOSTR_filter_TYPE.NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE? {
        return baseFilter.until
    }

    public var limit:UInt32? {
        return baseFilter.limit
    }

    public var authors:Set<PublicKey>? {
        return baseFilter.authors
    }

    public var genericTags: [Character:[any NOSTR_tag_index]]? {
        return baseFilter.genericTags
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