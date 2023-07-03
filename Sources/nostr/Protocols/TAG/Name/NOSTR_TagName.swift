/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
/// 	- `relay`
/// 	- `challenge`
public protocol NOSTR_TagName_proto:CodingKey, Codable, ExpressibleByStringLiteral, Hashable, Equatable where NOSTR_TagName_Primitive_Type:LosslessStringConvertible {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_TagName_Primitive_Type = LosslessStringConvertible

	/// represents the nostr tag name as a string representation.
	var NOSTR_TagName:NOSTR_TagName_Primitive_Type { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_TagName:NOSTR_TagName_Primitive_Type) throws
}


extension LosslessStringConvertible where Self:NOSTR_TagName_proto {
	typealias NOSTR_TagName_Primitive_Type = String
	public init(NOSTR_TagName:Self.NOSTR_TagName_Primitive_Type) throws {
		let getDesc = NOSTR_TagName.description
		guard getDesc.count > 0 else {
			throw Event.Tag.Name.ZeroLengthError()
		}
		self.init(getDesc)!
	}
	public var description:String {
		return self.description
	}
}

extension NOSTR_TagName_proto where NOSTR_TagName_Primitive_Type == String {
	public init?(stringValue:String) {
		guard stringValue.count > 0 else {
			return nil
		}
		try? self.init(NOSTR_TagName:stringValue)
	}
	public var stringValue:String {
		return self.NOSTR_TagName.description
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

extension NOSTR_TagName_proto where NOSTR_TagName_Primitive_Type:LosslessStringConvertible {
	public init?(stringValue:String) {
		guard stringValue.count > 0 else {
			return nil
		}
		try? self.init(NOSTR_TagName:NOSTR_TagName_Primitive_Type(stringValue)!)
	}
	public var stringValue:String {
		return self.NOSTR_TagName.description
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

// default implementation for Decodable
extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type:Decodable {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let getVal = try container.decode(NOSTR_TagName_Primitive_Type.self)
		try self.init(NOSTR_TagName:getVal)
	}
}

// default implementation for Encodable
extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type:Encodable {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.stringValue)
	}
}

extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type == String {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_TagName:value)
	}
}

extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type:LosslessStringConvertible {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_TagName:NOSTR_TagName_Primitive_Type(value)!)
	}
}

extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type:Hashable {
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.NOSTR_TagName)
	}
}

extension NOSTR_TagName_proto where Self.NOSTR_TagName_Primitive_Type:Equatable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.NOSTR_TagName == rhs.NOSTR_TagName
	}
}