// (c) tanner silva 2023. all rights reserved.
public protocol NOSTR_filter<NOSTR_filter_event_TYPE>:Codable {
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

	/// main initializer for the filter.
	init(uids:Set<Event.Signed.UID>?, kinds:Set<NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE>?, since:NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE?, until:NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE?, limit:UInt32?, authors:Set<nostr.PublicKey>?, genericTags:[Character:[any NOSTR_tag_index]]?)
}

// implements some default functionality for the filter
extension NOSTR_filter {
	/// determines if the given event matches the filter (requires that the event and filter events are of the same kind type)
	public func matches<E>(_ event:E) -> Bool where E:NOSTR_event_signed, E.NOSTR_event_kind_TYPE == NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE {
		if self.uids != nil && self.uids!.count > 0 {
			if self.uids!.contains(event.uid) {
				return true
			}
		}
		if self.kinds != nil && self.kinds!.count > 0 {
			if self.kinds!.contains(event.kind) {
				return true
			}
		}
		if self.since != nil {
			if event.date.NOSTR_date_unixInterval > self.since!.NOSTR_date_unixInterval {
				return true
			}
		}
		if self.until != nil {
			if event.date.NOSTR_date_unixInterval < self.until!.NOSTR_date_unixInterval {
				return true
			}
		}
		if self.authors != nil && self.authors!.count > 0 {
			if authors!.contains(event.author) {
				return true
			}
		}
		if genericTags != nil && genericTags!.count > 0 {
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

// default implementation of codable
extension NOSTR_filter {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if self.uids != nil {
			try container.encode(uids!, forKey:.ids)
		}
		if self.kinds != nil {
			try container.encode(kinds!, forKey:.kinds)
		}
		if self.since != nil {
			try container.encode(since!.NOSTR_date_unixInterval, forKey:.since)
		}
		if until != nil {
			try container.encode(until!.NOSTR_date_unixInterval, forKey:.until)
		}
		if limit != nil {
			try container.encode(limit!, forKey:.limit)
		}
		if authors != nil {
			try container.encode(authors!, forKey:.authors)
		}
		if genericTags != nil {
			try genericTags!.forEach({ (char, tags) in
				try container.encode(tags.map({ $0.NOSTR_tag_index }), forKey:.genericTagDescription(char))
			})
		}
	}

	public init(from decoder:Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let allKeys = container.allKeys
		let uids = try container.decodeIfPresent(Set<Event.Signed.UID>.self, forKey:.ids)
		let kinds = try container.decodeIfPresent(Set<NOSTR_filter_event_TYPE.NOSTR_event_kind_TYPE>.self, forKey:.kinds)
		let since = try container.decodeIfPresent(UInt64.self, forKey:.since)
		let sinceDate = since != nil ? NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE(NOSTR_date_unixInterval:since!) : nil
		let until = try container.decodeIfPresent(UInt64.self, forKey:.until)
		let untilDate = until != nil ? NOSTR_filter_event_TYPE.NOSTR_event_date_TYPE(NOSTR_date_unixInterval:until!) : nil
		let limit = try container.decodeIfPresent(UInt32.self, forKey:.limit)
		let authors = try container.decodeIfPresent(Set<nostr.PublicKey>.self, forKey:.authors)
		var buildTags = [Character:[any NOSTR_tag_index]]()
		for curTag in allKeys {
			switch curTag {
				case .genericTagDescription(let char):
					let tagValues = try container.decode([String].self, forKey:curTag)
					buildTags[char] = tagValues
				default:
					continue
			}
		}
		self.init(uids:uids, kinds:kinds, since:sinceDate, until:untilDate, limit:limit, authors:authors, genericTags:buildTags)
	}
}

// coding keys for the filter struct
fileprivate enum CodingKeys:CodingKey {

	case ids
	case kinds
	case since
	case until
	case authors
	case limit
	case genericTagDescription(Character)

	var stringValue:String {
		switch self {
			case .ids:
				return "ids"
			case .kinds:
				return "kinds"
			case .since:
				return "since"
			case .until:
				return "until"
			case .authors:	
				return "authors"
			case .limit:	
				return "limit"
			case let .genericTagDescription(char):
				return "#\(char)"
		}
	}
	init?(stringValue:String) {
		if stringValue.first == "#" && stringValue.count == 2 {
			self = .genericTagDescription(stringValue.last!)
		} else {
			switch stringValue {
			case "ids":
				self = .ids
			case "kinds":
				self = .kinds
			case "since":
				self = .since
			case "until":
				self = .until
			case "authors":
				self = .authors
			case "limit":
				self = .limit
			default:
				return nil
			}
		}
		
	}
	var intValue: Int? {
		return nil
	}
	init?(intValue: Int) {
		return nil
	}
}
