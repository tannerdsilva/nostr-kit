public protocol NOSTR_tags:Codable, ExpressibleByArrayLiteral, Collection where Element == any NOSTR_tagged_inst {
	associatedtype ArrayLiteralType = [any NOSTR_tagged_inst]
    init<T>(_ tags: T) where T: Collection, T.Element:NOSTR_tagged_inst
}

extension NOSTR_tags {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.unkeyedContainer()
		for tag in self {
			try container.encode(tag)
		}
	}
	public init(from decoder:Decoder) throws {
		var container = try decoder.unkeyedContainer()
		var tags = [Element]()
		while !container.isAtEnd {
			let tag = try container.decode(Element.self)
			tags.append(tag)
		}
		self.init(tags)
	}
}