public protocol NOSTR_tag_info_field:ExpressibleByStringLiteral {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_TYPE_tag_info_field:LosslessStringConvertible

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_info_field:NOSTR_TYPE_tag_info_field { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_info_field:NOSTR_TYPE_tag_info_field) throws
}

extension NOSTR_tag_info_field where NOSTR_TYPE_tag_info_field:LosslessStringConvertible {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_tag_info_field:NOSTR_TYPE_tag_info_field(value)!)
	}
}

extension String:NOSTR_tag_info_field {
	public var NOSTR_tag_info_field:String {
		return self
	}
	public init(NOSTR_tag_info_field value:String) throws {
		self = value
	}
}

extension Substring:NOSTR_tag_info_field {
	public var NOSTR_tag_info_field:String {
		return String(self)
	}
	public init(NOSTR_tag_info_field value:String) throws {
		self = value[...]
	}
}