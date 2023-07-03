/// a default implementation of all the required protocols for a nostr tag name.
public typealias NOSTR_TagName_impl = NOSTR_TagName_expl & CodingKey & Codable & LosslessStringConvertible & ExpressibleByStringLiteral

/// the discrete protocol for conveying nostr tag names.
/// encodes to and from a string that represents the "tag name" and is encoded in the apropriate places where needed.
/// - examples of tag names:
/// 	- `#a`
/// 	- `#p`
///		- `relay`
///		- `challenge`
public protocol NOSTR_TagName_expl:CodingKey, Codable, LosslessStringConvertible, ExpressibleByStringLiteral, Hashable, Equatable {
	/// represents the nostr tag name as a string representation.
	var NOSTR_TagName:String { get }

	/// initialize from a string representation of the nostr tag name.
	/// - NOTE: should throw if passed a zero-length string.
	init(NOSTR_TagName:String) throws
}

// default implementation for CodingKey
extension CodingKey where Self:NOSTR_TagName_impl {
	public init?(stringValue:String) {
		try? self.init(NOSTR_TagName:stringValue)
	}
	public var stringValue:String {
		return self.NOSTR_TagName
	}
	public init?(intValue:Int) {
		return nil
	}
	public var intValue:Int? {
		return nil
	}
}

// default implementation for Decodable
extension Decodable where Self:NOSTR_TagName_impl {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let getVal: String = try container.decode(String.self)
		try self.init(NOSTR_TagName:getVal)
	}
}

// default implementation for Encodable
extension Encodable where Self:NOSTR_TagName_impl {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.NOSTR_TagName)
	}
}

// default implementation for LosslessStringConvertible
extension LosslessStringConvertible where Self:NOSTR_TagName_impl {
	public init?(_ description: String) {
		try? self.init(NOSTR_TagName:description)
	}
	public var description:String {
		return self.NOSTR_TagName
	}
}

extension ExpressibleByStringLiteral where Self:NOSTR_TagName_impl {
	public init(stringLiteral value: String) {
		try! self.init(NOSTR_TagName:value)
	}
}

// // String can directly apply an explicit conformance to NOSTR_TagName_expl
// extension String:NOSTR_TagName_expl {
// 	public var NOSTR_TagName:String {
// 		return self
// 	}
// 	public init(NOSTR_TagName value:String) throws {
// 		guard value.count > 0 else {
// 			throw Event.Tag.Name.ZeroLengthError()
// 		}
// 		self = value
// 	}
// }	