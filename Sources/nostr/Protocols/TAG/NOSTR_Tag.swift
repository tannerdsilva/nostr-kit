#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public typealias NOSTR_Tag_impl = NOSTR_Tag_expl & Codable & Collection & ExpressibleByArrayLiteral

/// an unkeyed container of stringlike objects, whose contents represent a concept in nostr known as "tags".
/// - the first element of the array is the tag name, and the rest are additional info.
public protocol NOSTR_Tag_expl:Codable, ExpressibleByArrayLiteral, Collection where Element == String {
	
	/// the type of name for the tag. this distinguishes the type of content it contains.
	associatedtype NOSTR_TagName_Type:NOSTR_TagName_expl

	/// the type of content the tag contains.
	/// - must be some string-like codable type
	associatedtype NOSTR_TagInfo_Type:LosslessStringConvertible & Codable 

	/// the tag name (signifies the type of data it contains)
	var NOSTR_TagName:NOSTR_TagName_Type { get }

	/// additional info associated with the tag
	var NOSTR_TagInfo:[NOSTR_TagInfo_Type] { get }

	/// initialize from a tag name and tag info
	init(NOSTR_TagName:NOSTR_TagName_Type, NOSTR_TagInfo:[NOSTR_TagInfo_Type])
}

// collection conformance.
// for this protocol, we are implementing a collection of lossless string convertibles.
extension Collection where Self:NOSTR_Tag_impl {
	public typealias Index = size_t
	public var startIndex:size_t {
		return 0
	}
	public var endIndex:size_t {
		return self.count + 1
	}
	public func index(after i:size_t) -> size_t {
		return i + 1
	}
	public func index(before i:size_t) -> size_t {
		return i - 1
	}
	public subscript(position:size_t) -> String {
		switch position {
			case 0:
				return self.NOSTR_TagName.description
			default:
				return self.NOSTR_TagInfo[position - 1].description
		}
	}
}

// event tag - decodable
extension Decodable where Self:NOSTR_Tag_impl {
	// decode implementation
	public init(from decoder:Decoder) throws {
		var container = try decoder.unkeyedContainer()
		let tagName = try container.decode(NOSTR_TagName_Type.self)
		var buildArray = [NOSTR_TagInfo_Type]()
		while container.isAtEnd == false {
			buildArray.append(try container.decode(NOSTR_TagInfo_Type.self))
		}
		self.init(NOSTR_TagName:tagName, NOSTR_TagInfo:buildArray)
	}
}

// event tag - encodable
extension Encodable where Self:NOSTR_Tag_impl {
	// encode implementation
	public func encode(to encoder:Encoder) throws {
		var nameContainer = encoder.unkeyedContainer()
		try nameContainer.encode(self.NOSTR_TagName)
		for curInfo in self.NOSTR_TagInfo {
			try nameContainer.encode(curInfo)
		}
	}
}

extension ExpressibleByArrayLiteral where Self:NOSTR_Tag_impl {
	// array literal implementation
	public init(arrayLiteral elements: String...) {
		precondition(elements.count > 0, "cannot initialize with empty array literal")
		let tagName = try! NOSTR_TagName_Type(NOSTR_TagName:elements[0])
		var buildArray = [NOSTR_TagInfo_Type]()
		for curInfo in elements[1...] {
			buildArray.append(NOSTR_TagInfo_Type(curInfo)!)
		}
		self.init(NOSTR_TagName:tagName, NOSTR_TagInfo:buildArray)
	}
}