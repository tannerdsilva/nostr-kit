public protocol NOSTR_tagged:NOSTR_tag {
	associatedtype Element = String // element must be string literal since any of the sub protocols that can be found in the body of this type
	associatedtype ArrayLiteralType = String

	// bind the static and the instance type together
	associatedtype NOSTR_tagged_name_TYPE:NOSTR_tag_name = nostr.Event.Tag.Name
	associatedtype NOSTR_tag_name_TYPE = NOSTR_tagged_name_TYPE

	static var NOSTR_tagged_name:NOSTR_tagged_name_TYPE { get }

	init(NOSTR_tag_index:NOSTR_tag_index_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

extension NOSTR_tagged where Self:NOSTR_tag, Self.NOSTR_tag_name_TYPE == Self.NOSTR_tagged_name_TYPE {
	public var NOSTR_tag_namefield: NOSTR_tag_name_TYPE {
		return Self.NOSTR_tagged_name
	}
	public init(NOSTR_tag_name:NOSTR_tag_name_TYPE, NOSTR_tag_index:NOSTR_tag_index_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws {
		guard NOSTR_tag_name.NOSTR_tag_name == Self.NOSTR_tagged_name.NOSTR_tag_name else {
			fatalError("someone fucked up here")
		}
		try self.init(NOSTR_tag_index:NOSTR_tag_index, NOSTR_tag_addlfields:NOSTR_tag_addlfields)
	}
}