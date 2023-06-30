// (c) tanner silva 2023. all rights reserved.

/// standard nostr relay filter
public struct Filter {
	/// event uids to filter by
	public var ids:Set<String>?
	/// event kinds to filter by
	public var kinds:Set<nostr.Event.Kind>? = nil
	/// retruned events will be limited to those that follow this date
	public var since:Date?
	/// returned events will be limited to those that precede this date
	public var until:Date?
	/// limit the number of events returned
	public var limit:UInt32?
	/// returned events must be authored by one of these public keys
	public var authors:Set<nostr.Key>?

	/// returned events must contain one of the following event id `#e` tags
	public var tag_referenced_ids:Set<String>?
	/// returned events must contain one of the following public key `#p` tags
	public var tag_pubkeys:Set<nostr.Key>?
	/// returned events must contain one of the following hashtag `#t` tags
	public var tag_hashtag:Set<String>?
	/// returned events must contain one of the following parameter `#d` tags
	public var tag_parameter:Set<String>?
	
	/// create a new filter
	public init(
		ids:Set<String>? = nil,
		kinds:Set<nostr.Event.Kind>? = nil,
		since:Date? = nil,
		until:Date? = nil,
		limit:UInt32? = nil,
		authors:Set<nostr.Key>? = nil,
		tag_referenced_ids:Set<String>? = nil,
		tag_pubkeys:Set<nostr.Key>? = nil,
		tag_hashtag:Set<String>? = nil,
		tag_parameter:Set<String>? = nil
	) {
		self.ids = ids
		self.kinds = kinds
		self.since = since
		self.until = until
		self.limit = limit
		self.authors = authors
		self.tag_referenced_ids = tag_referenced_ids
		self.tag_pubkeys = tag_pubkeys
		self.tag_hashtag = tag_hashtag
		self.tag_parameter = tag_parameter
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
			self.authors = try container.decode(Set<nostr.Key>.self, forKey: .authors)
		} catch {
			self.authors = nil
		}
		do {
			self.limit = try container.decode(UInt32.self, forKey: .limit)
		} catch {
			self.limit = nil
		}
		do {
			self.tag_referenced_ids = try container.decode(Set<String>.self, forKey: .tag_referenced_ids)
		} catch {
			self.tag_referenced_ids = nil
		}
		do {
			self.tag_pubkeys = try container.decode(Set<nostr.Key>.self, forKey: .tag_pubkeys)
		} catch {
			self.tag_pubkeys = nil
		}
		do {
			self.tag_hashtag = try container.decode(Set<String>.self, forKey: .tag_hashtag)
		} catch {
			self.tag_hashtag = nil
		}
		do {
			self.tag_parameter = try container.decode(Set<String>.self, forKey: .tag_parameter)
		} catch {
			self.tag_parameter = nil
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
		if self.tag_referenced_ids != nil {
			try container.encode(tag_referenced_ids, forKey: .tag_referenced_ids)
		}
		if self.tag_pubkeys != nil {
			try container.encode(tag_pubkeys, forKey: .tag_pubkeys)
		}
		if self.tag_hashtag != nil {
			try container.encode(tag_hashtag, forKey: .tag_hashtag)
		}
		if self.tag_parameter != nil {
			try container.encode(tag_parameter, forKey: .tag_parameter)
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
			&& lhs.tag_referenced_ids == rhs.tag_referenced_ids
			&& lhs.tag_pubkeys == rhs.tag_pubkeys
			&& lhs.tag_hashtag == rhs.tag_hashtag
			&& lhs.tag_parameter == rhs.tag_parameter
	}
	public func hash(into hasher:inout Hasher) {
		hasher.combine(ids)
		hasher.combine(kinds)
		hasher.combine(since)
		hasher.combine(until)
		hasher.combine(authors)
		hasher.combine(limit)
		hasher.combine(tag_referenced_ids)
		hasher.combine(tag_pubkeys)
		hasher.combine(tag_hashtag)
		hasher.combine(tag_parameter)
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

	case tag_referenced_ids = "#e"
	case tag_pubkeys = "#p"
	case tag_hashtag = "#t"
	case tag_parameter = "#d"
}
