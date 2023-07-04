/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
/// 	- `relay`
/// 	- `challenge`
public protocol NOSTR_tag_name:CodingKey, Codable, ExpressibleByStringLiteral, Hashable, Equatable {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_tag_name_REPTYPE = LosslessStringConvertible

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_name:NOSTR_tag_name_REPTYPE { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_name:NOSTR_tag_name_REPTYPE) throws
}

// string uses itself as the associatedtype to conform to the protocol
extension String:NOSTR_tag_name {
	public typealias NOSTR_tag_name_REPTYPE = Self
	public var NOSTR_tag_name:NOSTR_tag_name_REPTYPE {
		return self
	}
	public init(NOSTR_tag_name:NOSTR_tag_name_REPTYPE) throws {
		self = NOSTR_tag_name
	}
}

// default implementations when the associatedtype is a string
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE == String {
	// codingkey
	public init?(stringValue:String) {
		try? self.init(NOSTR_tag_name:stringValue)
	}
	public var stringValue:String {
		return self.NOSTR_tag_name
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE == String {
	// expressiblebystringliteral
	public init(stringLiteral value:String) {
		try! self.init(NOSTR_tag_name:value)
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE == String {
	// hashable
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.NOSTR_tag_name)
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE == String {
	// equatable
	public static func ==(lhs:Self, rhs:Self) -> Bool {
		return lhs.NOSTR_tag_name == rhs.NOSTR_tag_name
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE == String {
	// codable
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		try self.init(NOSTR_tag_name:string)
	}
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.NOSTR_tag_name)
	}
}

// default implementations when the associatedtype is losslessstringconvertible
extension LosslessStringConvertible where Self:NOSTR_tag_name {
	typealias NOSTR_tag_name_REPTYPE = Self
	public init(NOSTR_tag_name:Self) throws {
		self = NOSTR_tag_name
	}
	public var NOSTR_tag_name:Self {
		return self
	}
}

extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE:LosslessStringConvertible {
	// codingkey
	public init?(stringValue:String) {
		guard let makeRepType = NOSTR_tag_name_REPTYPE(stringValue) else {
			return nil
		}
		try? self.init(NOSTR_tag_name:makeRepType)
	}
	public var stringValue:String {
		return self.NOSTR_tag_name.description
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE:LosslessStringConvertible {
	// expressiblebystringliteral
	public init(stringLiteral value:String) {
		try! self.init(NOSTR_tag_name:NOSTR_tag_name_REPTYPE(value)!)
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE:LosslessStringConvertible {
	// hashable
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.NOSTR_tag_name.description)
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE:LosslessStringConvertible {
	// equatable
	public static func ==(lhs:Self, rhs:Self) -> Bool {
		return lhs.NOSTR_tag_name.description == rhs.NOSTR_tag_name.description
	}
}
extension NOSTR_tag_name where NOSTR_tag_name_REPTYPE:LosslessStringConvertible {
	// codable
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		guard let makeRepType = NOSTR_tag_name_REPTYPE(string) else {
			throw DecodingError.dataCorruptedError(in:container, debugDescription:"could not convert string to \(NOSTR_tag_name_REPTYPE.self)")
		}
		try self.init(NOSTR_tag_name:makeRepType)
	}
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.NOSTR_tag_name.description)
	}
}