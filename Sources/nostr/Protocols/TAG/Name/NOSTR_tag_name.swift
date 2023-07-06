/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
/// 	- `relay`
/// 	- `challenge`

public protocol NOSTR_tag_namefield:ExpressibleByStringLiteral {
	associatedtype NOSTR_tag_namefield_ERROR_zerolength:Swift.Error

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_namefield:String { get }

	/// initialize from a string representation of the nostr tag name.
	/// - MUST throw `NOSTR_tag_namefield_ERROR_zerolength` if the string representation is zero length.
	init(NOSTR_tag_namefield:String) throws
}

// everyone gets a default implementation of EspressibleByStringLiteral
extension NOSTR_tag_namefield {
	public init(stringLiteral value:String) {
		guard value.NOSTR_tag_namefield.count > 0 else {
			fatalError("string literal for NOSTR_tag_namefield must be non-zero length")
		}
		try! self.init(NOSTR_tag_namefield:value)
	}
}

// string implementation for protocol
extension String:NOSTR_tag_namefield {
	public typealias NOSTR_tag_namefield_ERROR_zerolength = nostr.Event.Tag.Name.ZeroLengthError
	public var NOSTR_tag_namefield:String {
		return self
	}
	public init(NOSTR_tag_namefield:String) throws {
		guard NOSTR_tag_namefield.count > 0 else {
			throw NOSTR_tag_namefield_ERROR_zerolength()
		}
		self = NOSTR_tag_namefield
	}
}

// substring implementation for protocol
extension Substring:NOSTR_tag_namefield {
	public typealias NOSTR_tag_namefield_ERROR_zerolength = nostr.Event.Tag.Name.ZeroLengthError
	public var NOSTR_tag_namefield:String {
		return String(self)
	}
	public init(NOSTR_tag_namefield:String) throws {
		guard NOSTR_tag_namefield.count > 0 else {
			throw NOSTR_tag_namefield_ERROR_zerolength()
		}
		self = NOSTR_tag_namefield[...]
	}
}