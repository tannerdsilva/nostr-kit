import QuickJSON

public protocol NOSTR_event_unsigned {
	/// the date type that is used for the event
	associatedtype NOSTR_event_date_TYPE:NOSTR_date = nostr.Date
	/// the event kind type that is used for the event
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind = nostr.Event.Kind

	/// the date when the event was created. this value may be nil if the intent is to date this event when it is signed
	var date:NOSTR_date? { get }
	/// the tags attached to the event
	var tags:Array<any NOSTR_tag> { get }
	/// the kind of event
	var kind:NOSTR_event_kind_TYPE { get }
	/// the content of the event
	var content:String { get }
}

/// a protocol for expressing a complete nostr event.
public protocol NOSTR_event_signed:Codable, NOSTR_event_unsigned {
	/// the unique identifier for the event
	var uid:Event.UID { get }
	/// the cryptographic signature for the event
	var sig:Event.Signature { get }
	/// the tags attached to the event
	var tags:Event.Tags { get }
	/// the author of the event
	var author:PublicKey { get }
	/// the creation date of the event
	var date:NOSTR_event_date_TYPE { get }
	/// the kind of event
	var kind:NOSTR_event_kind_TYPE { get }
	/// the content of the event
	var content:String { get }

	/// initialize a new instance of the signed event based on the given parameters
	init(uid:Event.UID, sig:Event.Signature, tags:Event.Tags, author:PublicKey, date:NOSTR_event_date_TYPE, kind:NOSTR_event_kind_TYPE, content:String) throws
	/// returns true if the event is cryptographically valid. otherwise, will return false.
	func isValid() -> Bool
}

extension NOSTR_event_signed {
	init<U>(unsigned:U, author:KeyPair) throws where U:NOSTR_event_unsigned, U.NOSTR_event_kind_TYPE == NOSTR_event_kind_TYPE {
		let eventEncoder = QuickJSON.Encoder()
		let tagsString = String(bytes:try eventEncoder.encode(unsigned.tags.compactMap { Array($0) }), encoding:.utf8)
		let contentString = String(bytes:try eventEncoder.encode(unsigned.content), encoding:.utf8)
		let writeDate = unsigned.date ?? NOSTR_event_date_TYPE()
		let commitment = "[0,\"\(author.publicKey.hexEncodedString)\",\(Int64(writeDate.timeIntervalSinceUnixDate())),\(unsigned.kind.rawValue),\(tagsString!),\(contentString!)]"
	}
}

/// implement Codable conformance
extension NOSTR_event_signed {
	/// encode implementation
	public func encode(to encoder:Encoder) throws {
		var container = encoder.container(keyedBy:Event.CodingKeys.self)
		try container.encode(uid, forKey:.uid)
		try container.encode(sig, forKey:.sig)
		var nestedUnkeyedContainer = container.nestedUnkeyedContainer(forKey:.tags)
		for curTag in tags {
			try nestedUnkeyedContainer.encode(curTag)
		}
		try container.encode(author, forKey: .author)
		try container.encode(date.NOSTR_date_unixInterval, forKey:.date)
		try container.encode(kind, forKey: .kind)
		try container.encode(content, forKey: .content)
	}

	/// decode implementation
	public init(from decoder:Decoder) throws {
		let container = try decoder.container(keyedBy:Event.CodingKeys.self)
		let getUID = try container.decode(Event.UID.self, forKey:.uid)
		let getSig = try container.decode(Event.Signature.self, forKey:.sig)
		var tagsContainer = try container.nestedUnkeyedContainer(forKey:.tags)
		var buildTags = Event.Tags()
		while !tagsContainer.isAtEnd {
			let curTag = try tagsContainer.decode(Event.Tag.self)
			buildTags.append(curTag)
		}
		let getAuthor = try container.decode(PublicKey.self, forKey:.author)
		let getDate = try container.decode(UInt64.self, forKey:.date)
		let getKind = try container.decode(NOSTR_event_kind_TYPE.self, forKey:.kind)
		let getContent = try container.decode(String.self, forKey:.content)
		try self.init(uid:getUID, sig:getSig, tags:buildTags, pubkey:getAuthor, created:NOSTR_event_date_TYPE(NOSTR_date_unixInterval:getDate), kind:getKind, content:getContent)
	}
}