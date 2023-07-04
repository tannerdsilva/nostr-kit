/// represents an unkeyed container of string-like objects that represent tag metadata.
/// - may contain no entries.
public protocol NOSTR_Proto_TagInfo:Codable & Collection where Element == any NOSTR_Proto_TagInfoField {}

// default implementation for Decodable
extension Decodable where Self:NOSTR_Proto_TagInfoField {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let getVal: String = try container.decode(String.self)
		try self.init(NOSTR_TagName:[getVal])
	}
}

// default implementation for Encodable
extension Encodable where Self:NOSTR_TagName_impl {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.stringValue)
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