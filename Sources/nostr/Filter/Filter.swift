/// standard nostr relay filter
public struct Filter {
	/// event uids to filter by
	public var ids:Set<String>? = nil
	/// event kinds to filter by
	public var kinds:Set<nostr.Event.Kind>? = nil
	/// retruned events will be limited to those that follow this date
	public var since:Date? = nil
	/// returned events will be limited to those that precede this date
	public var until:Date? = nil
	/// limit the number of events returned
	public var limit:UInt32? = nil
	/// returned events must be authored by one of these public keys
	public var authors:Set<nostr.Key>? = nil

	/// returned events must contain one of the following event id `#e` tags
	public var tag_referenced_ids:Set<String>? = nil
	/// returned events must contain one of the following public key `#p` tags
	public var tag_pubkeys:Set<nostr.Key>? = nil
	/// returned events must contain one of the following hashtag `#t` tags
	public var tag_hashtag:Set<String>? = nil
	/// returned events must contain one of the following parameter `#d` tags
	public var tag_parameter:Set<String>? = nil
}

extension Filter:Codable {
	/// initialize using a standard swift decoder
	public init(from decoder:Swift.Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.ids = try container.decode(Set<String>.self, forKey: .ids)
		self.kinds = try container.decode(Set<nostr.Event.Kind>.self, forKey: .kinds)
		self.since = try container.decode(Date.self, forKey: .since)
		self.until = try container.decode(Date.self, forKey: .until)
		self.authors = try container.decode(Set<nostr.Key>.self, forKey: .authors)
		self.limit = try container.decode(UInt32.self, forKey: .limit)

		self.tag_referenced_ids = try container.decode(Set<String>.self, forKey: .referenced_ids)
		self.tag_pubkeys = try container.decode(Set<nostr.Key>.self, forKey: .pubkeys)
		self.tag_hashtag = try container.decode(Set<String>.self, forKey: .hashtag)
		self.tag_parameter = try container.decode(Set<String>.self, forKey: .parameter)
	}

	/// export to a standard swift encoder
	public func encode(to encoder:Swift.Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(ids, forKey: .ids)
		try container.encode(kinds, forKey: .kinds)
		try container.encode(since, forKey: .since)
		try container.encode(until, forKey: .until)
		try container.encode(authors, forKey: .authors)
		try container.encode(limit, forKey: .limit)

		try container.encode(tag_referenced_ids, forKey: .referenced_ids)
		try container.encode(tag_pubkeys, forKey: .pubkeys)
		try container.encode(tag_hashtag, forKey: .hashtag)
		try container.encode(tag_parameter, forKey: .parameter)
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

	case referenced_ids = "#e"
	case pubkeys = "#p"
	case hashtag = "#t"
	case parameter = "#d"
}
