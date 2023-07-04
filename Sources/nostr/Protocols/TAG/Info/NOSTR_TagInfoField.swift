public protocol NOSTR_Proto_TagInfoField:ExpressibleByStringLiteral {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_Proto_TagInfoField_ivartype

	/// represents the nostr tag name as a string representation.
	var NOSTR_Proto_TagInfoField_ivar:String { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_Proto_TagInfoField_ivar:String) throws
}

extension LosslessStringConvertible where Self:NOSTR_Proto_TagInfoField {
	public typealias NOSTR_TagInfoField_Primitive_Type = String
	public init(NOSTR_TagInfoField_ivar:Self.NOSTR_TagInfoField_Primitive_Type) throws {
		let getDesc = NOSTR_TagInfoField_ivar.description
		guard getDesc.count > 0 else {
			throw Event.Tag.Name.ZeroLengthError()
		}
		self.init(getDesc)!
	}
	public var description:String {
		return self.NOSTR_Proto_TagInfoField_ivar.description
	}
}


// default implementation for Decodable
extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype:Decodable {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let getVal = try container.decode(NOSTR_Proto_TagInfoField_ivartype.self)
		try self.init(NOSTR_Proto_TagInfoField_ivar:getVal)
	}
}

// default implementation for Encodable
extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype:Encodable {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.NOSTR_Proto_TagInfoField_ivar)
	}
}

extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype == String {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_Proto_TagInfoField_ivar:value)
	}
}

extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype:LosslessStringConvertible {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_Proto_TagInfoField_ivar:NOSTR_Proto_TagInfoField_ivartype(value)!)
	}
}

extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype:Hashable {
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.NOSTR_Proto_TagInfoField_ivar)
	}
}

extension NOSTR_Proto_TagInfoField where Self.NOSTR_Proto_TagInfoField_ivartype:Equatable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.NOSTR_Proto_TagInfoField_ivar == rhs.NOSTR_Proto_TagInfoField_ivar
	}
}