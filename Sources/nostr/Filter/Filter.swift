// (c) tanner silva 2023. all rights reserved.

/// standard nostr relay filter
public struct Filter {
	/// event uids to filter by
	public var ids:Set<String>?
	/// event kinds to filter by
	public var kinds:Set<nostr.Event.Kind>?
	/// retruned events will be limited to those that follow this date
	public var since:Date?
	/// returned events will be limited to those that precede this date
	public var until:Date?
	/// limit the number of events returned
	public var limit:UInt32?
	/// returned events must be authored by one of these public keys
	public var authors:Set<nostr.PublicKey>?

	/// create a new filter
	public init(
		ids:Set<String>? = nil,
		kinds:Set<nostr.Event.Kind>? = nil,
		since:Date? = nil,
		until:Date? = nil,
		limit:UInt32? = nil,
		authors:Set<nostr.PublicKey>? = nil
	) {
		self.ids = ids
		self.kinds = kinds
		self.since = since
		self.until = until
		self.limit = limit
		self.authors = authors
	}
}

extension Filter:Codable {
	/// initialize using a standard swift decoder
	public init(from decoder:Swift.Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		do {
			self.ids = try container.decode(Set<String>.self, forKey: .ids)
		} catch {
			self.ids = nil
		}
		do {
			self.kinds = try container.decode(Set<nostr.Event.Kind>.self, forKey: .kinds)
		} catch {
			self.kinds = nil
		}
		do {
			self.since = try container.decode(Date.self, forKey: .since)
		} catch {
			self.since = nil
		}
		do {
			self.until = try container.decode(Date.self, forKey: .until)
		} catch {
			self.until = nil
		}
		do {
			self.authors = try container.decode(Set<nostr.PublicKey>.self, forKey: .authors)
		} catch {
			self.authors = nil
		}
		do {
			self.limit = try container.decode(UInt32.self, forKey: .limit)
		} catch {
			self.limit = nil
		}
	}

	/// export to a standard swift encoder
	public func encode(to encoder:Swift.Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if self.ids != nil {
			try container.encode(ids, forKey: .ids)
		}
		if self.kinds != nil {
			try container.encode(kinds, forKey: .kinds)
		}
		if self.since != nil {
			try container.encode(since, forKey: .since)
		}
		if self.until != nil {
			try container.encode(until, forKey: .until)
		}
		if self.authors != nil {
			try container.encode(authors, forKey: .authors)
		}
		if self.limit != nil {
			try container.encode(limit, forKey: .limit)
		}
	}
}

extension nostr.Filter:Hashable, Equatable {
	public static func == (lhs:Filter, rhs:Filter) -> Bool {
		return lhs.ids == rhs.ids
			&& lhs.kinds == rhs.kinds
			&& lhs.since == rhs.since
			&& lhs.until == rhs.until
			&& lhs.authors == rhs.authors
			&& lhs.limit == rhs.limit
	}
	public func hash(into hasher:inout Hasher) {
		hasher.combine(ids)
		hasher.combine(kinds)
		hasher.combine(since)
		hasher.combine(until)
		hasher.combine(authors)
		hasher.combine(limit)
	}
}

// coding keys for the filter struct
fileprivate enum CodingKeys:String, CodingKey {
	case ids = "ids"
	case kinds = "kinds"
	case since = "since"
	case until = "until"
	case authors = "authors"
	case limit = "limit"
}
