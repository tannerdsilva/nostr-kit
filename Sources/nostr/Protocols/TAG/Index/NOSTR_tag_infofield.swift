/*
    ["e", <32-bytes hex of the id of another event>, <recommended relay URL>],
    ["p", <32-bytes hex of a pubkey>, <recommended relay URL>],
*/

public protocol NOSTR_tag_indexfield:ExpressibleByStringLiteral {
	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_indexfield:String { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_indexfield:String) throws
}

// everyone gets a default implementation of EspressibleByStringLiteral
extension NOSTR_tag_indexfield {
	public init(stringLiteral value:String) {
		try! self.init(NOSTR_tag_indexfield:value)
	}
}

// string implementation for protocol
extension String:NOSTR_tag_indexfield {
	public typealias NOSTR_tag_indexfield_ERROR_zerolength = nostr.Event.Tag.Name.ZeroLengthError
	public var NOSTR_tag_indexfield:String {
		return self
	}
	public init(NOSTR_tag_indexfield:String) throws {
		guard NOSTR_tag_indexfield.count > 0 else {
			throw NOSTR_tag_indexfield_ERROR_zerolength()
		}
		self = NOSTR_tag_indexfield
	}

}

// substring implementation for protocol
extension Substring:NOSTR_tag_indexfield {
	public typealias NOSTR_tag_indexfield_ERROR_zerolength = nostr.Event.Tag.Name.ZeroLengthError
	public var NOSTR_tag_indexfield:String {
		return String(self)
	}
	public init(NOSTR_tag_indexfield:String) throws {
		guard NOSTR_tag_indexfield.count > 0 else {
			throw NOSTR_tag_indexfield_ERROR_zerolength()
		}
		self = NOSTR_tag_indexfield[...]
	}
}