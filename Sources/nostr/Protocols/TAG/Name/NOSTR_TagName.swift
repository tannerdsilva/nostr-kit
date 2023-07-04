/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
/// 	- `relay`
/// 	- `challenge`
public protocol NOSTR_Proto_TagName:CodingKey, Codable, ExpressibleByStringLiteral, Hashable, Equatable where NOSTR_Proto_TagName_itype:LosslessStringConvertible {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_Proto_TagName_itype

	/// represents the nostr tag name as a string representation.
	var NOSTR_Proto_TagName_ivar:NOSTR_Proto_TagName_itype { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_Proto_TagName_ivar:NOSTR_Proto_TagName_itype) throws
}

extension String:NOSTR_Proto_TagName {
	public var NOSTR_Proto_TagName_ivar:String {
		return self
	}
	public init(NOSTR_Proto_TagName_ivar:String) throws {
		self = NOSTR_Proto_TagName_ivar
	}
}

extension String:CodingKey {
	public init?(stringValue:String) {
		guard stringValue.count > 0 else {
			return nil
		}
		try? self.init(NOSTR_Proto_TagName_ivar:stringValue)
	}
	public var stringValue:String {
		return self
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

extension LosslessStringConvertible where Self:NOSTR_Proto_TagName {
	public typealias NOSTR_Proto_TagName_itype = String
	public init(NOSTR_Proto_TagName_ivar:Self.NOSTR_Proto_TagName_itype) throws {
		let getDesc = NOSTR_Proto_TagName_ivar.description
		guard getDesc.count > 0 else {
			throw Event.Tag.Name.ZeroLengthError()
		}
		self.init(getDesc)!
	}
	public var description:String {
		return self.description
	}
}

extension NOSTR_Proto_TagName where NOSTR_Proto_TagName_itype == String {
	public init?(stringValue:String) {
		guard stringValue.count > 0 else {
			return nil
		}
		try? self.init(NOSTR_Proto_TagName_ivar:stringValue)
	}
	public var stringValue:String {
		return self.NOSTR_Proto_TagName_ivar.description
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

extension NOSTR_Proto_TagName where NOSTR_Proto_TagName_itype:LosslessStringConvertible {
	public init?(stringValue:String) {
		guard stringValue.count > 0 else {
			return nil
		}
		try? self.init(NOSTR_Proto_TagName_ivar:NOSTR_Proto_TagName_itype(stringValue)!)
	}
	public var stringValue:String {
		return self.NOSTR_Proto_TagName_ivar.description
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

// default implementation for Decodable
extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype:Decodable {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let getVal = try container.decode(NOSTR_Proto_TagName_itype.self)
		try self.init(NOSTR_Proto_TagName_ivar:getVal)
	}
}

// default implementation for Encodable
extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype:Encodable {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.stringValue)
	}
}

extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype == String {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_Proto_TagName_ivar:value)
	}
}

extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype:LosslessStringConvertible {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_Proto_TagName_ivar:NOSTR_Proto_TagName_itype(value)!)
	}
}

extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype:Hashable {
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.NOSTR_Proto_TagName_ivar)
	}
}

extension NOSTR_Proto_TagName where Self.NOSTR_Proto_TagName_itype:Equatable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.NOSTR_Proto_TagName_ivar == rhs.NOSTR_Proto_TagName_ivar
	}
}