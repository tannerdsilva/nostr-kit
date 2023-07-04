/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
/// 	- `relay`
/// 	- `challenge`

public protocol NOSTR_tag_name:ExpressibleByStringLiteral {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_TYPE_tag_name_p

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_name:NOSTR_TYPE_tag_name_p { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_name:NOSTR_TYPE_tag_name_p) throws
}

extension NOSTR_tag_name where NOSTR_TYPE_tag_name:LosslessStringConvertible {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_tag_name:NOSTR_TYPE_tag_name(value)!)
	}
}

extension String:NOSTR_tag_name {
	public var NOSTR_tag_name:String {
		return self
	}
	public init(NOSTR_tag_name value:String) throws {
		self = value
	}
}

extension Substring:NOSTR_tag_name {
	public var NOSTR_tag_name:String {
		return String(self)
	}
	public init(NOSTR_tag_name value:String) throws {
		self = value[...]
	}
}