// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_tag_addlfield:ExpressibleByStringLiteral {
	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_addlfield:String { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_addlfield:String) throws
}

// everyone gets a default implementation of EspressibleByStringLiteral
extension NOSTR_tag_addlfield {
	public init(stringLiteral value:String) {
		try! self.init(NOSTR_tag_addlfield:value)
	}
}

// string implementation for protocol
extension String:NOSTR_tag_addlfield {
	public var NOSTR_tag_addlfield:String {
		return self
	}
	public init(NOSTR_tag_addlfield:String) throws {
		self = NOSTR_tag_addlfield
	}
}

// substring implementation for protocol
extension Substring:NOSTR_tag_addlfield {
	public var NOSTR_tag_addlfield:String {
		return String(self)
	}
	public init(NOSTR_tag_addlfield:String) throws {
		self = NOSTR_tag_addlfield[...]
	}
}