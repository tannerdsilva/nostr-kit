// (c) tanner silva 2023. all rights reserved.

public protocol NOSTR_tag_name:ExpressibleByStringLiteral {
	associatedtype NOSTR_tag_name_ERROR_zerolength:Swift.Error = nostr.Event.Tag.Name.ZeroLengthError

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_name:String { get }

	/// initialize from a string representation of the nostr tag name.
	/// - MUST throw `NOSTR_tag_name_ERROR_zerolength` if the string representation is zero length.
	init(NOSTR_tag_name:String) throws
}

// everyone gets a default implementation of EspressibleByStringLiteral
extension NOSTR_tag_name {
	public init(stringLiteral value:String) {
		guard value.NOSTR_tag_name.count > 0 else {
			fatalError("string literal for NOSTR_tag_name must be non-zero length")
		}
		try! self.init(NOSTR_tag_name:value)
	}
}

// string implementation for protocol
extension String:NOSTR_tag_name {
	public var NOSTR_tag_name:String {
		return self
	}
	public init(NOSTR_tag_name:String) throws {
		guard NOSTR_tag_name.count > 0 else {
			throw NOSTR_tag_name_ERROR_zerolength()
		}
		self = NOSTR_tag_name
	}
}

// substring implementation for protocol
extension Substring:NOSTR_tag_name {
	public var NOSTR_tag_name:String {
		return String(self)
	}
	public init(NOSTR_tag_name:String) throws {
		guard NOSTR_tag_name.count > 0 else {
			throw NOSTR_tag_name_ERROR_zerolength()
		}
		self = NOSTR_tag_name[...]
	}
}