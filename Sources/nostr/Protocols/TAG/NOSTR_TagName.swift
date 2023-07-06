public protocol NOSTR_tagged_type {
	associatedtype NOSTR_tagged_type_namefield_TYPE:NOSTR_tag_namefield
	associatedtype NOSTR_tagged_type_indexfield_TYPE:NOSTR_tag_indexfield
	static var NOSTR_tagged_type_namefield:NOSTR_tagged_type_namefield_TYPE { get }
	init(NOSTR_tag_indexfield:NOSTR_tagged_type_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

extension NOSTR_tagged_inst where Self:NOSTR_tagged_type, NOSTR_tagged_type_namefield_TYPE == NOSTR_tag_namefield_TYPE {
	public var NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE {
		return Self.NOSTR_tagged_type_namefield
	}
	public init(NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws {
		try self.init(NOSTR_tag_namefield:Self.NOSTR_tagged_type_namefield, NOSTR_tag_indexfield:NOSTR_tag_indexfield, NOSTR_tag_addlfields:NOSTR_tag_addlfields)
	}
}

public protocol NOSTR_tagged_inst:ExpressibleByArrayLiteral {
	associatedtype ArrayLiteralType = String
	associatedtype NOSTR_tag_namefield_TYPE:NOSTR_tag_namefield
	associatedtype NOSTR_tag_indexfield_TYPE:NOSTR_tag_indexfield

	var NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE { get }
	var NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE { get }
	var NOSTR_tag_addlfields:[any NOSTR_tag_addlfield] { get }

	init(NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE, NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

// everyone gets a default implementation of the encoding and decoding
extension NOSTR_tagged_inst {
	// encode
	// unkeyed container
	internal func encode(unkeyedForm unkeyedContainer:inout UnkeyedEncodingContainer) throws {
		try unkeyedContainer.encode(NOSTR_tag_namefield.NOSTR_tag_namefield)
		try unkeyedContainer.encode(NOSTR_tag_indexfield.NOSTR_tag_indexfield)
		for addlfield in self.NOSTR_tag_addlfields {
			try unkeyedContainer.encode(addlfield.NOSTR_tag_addlfield)
		}
	}

	// decode
	// unkeyed container
	internal init(unkeyedForm unkeyedContainer:inout UnkeyedDecodingContainer) throws {
		let makeName = try NOSTR_tag_namefield_TYPE(NOSTR_tag_namefield:try unkeyedContainer.decode(String.self))
		let makeIndexField = try NOSTR_tag_indexfield_TYPE(NOSTR_tag_indexfield:try unkeyedContainer.decode(String.self))
		var makeAddlFields:[any NOSTR_tag_addlfield] = []
		while !unkeyedContainer.isAtEnd {
			makeAddlFields.append(try unkeyedContainer.decode(String.self))
		}
		try self.init(NOSTR_tag_namefield:makeName, NOSTR_tag_indexfield:makeIndexField, NOSTR_tag_addlfields:makeAddlFields)
	}
}

// everyone gets a default implementation of EspressibleByArrayLiteral
extension NOSTR_tagged_inst {
	public init(arrayLiteral elements:String...) {
		let makeName = try! NOSTR_tag_namefield_TYPE(NOSTR_tag_namefield:elements[0])
		let makeIndexField = try! NOSTR_tag_indexfield_TYPE(NOSTR_tag_indexfield:elements[1])
		var makeAddlFields:[any NOSTR_tag_addlfield] = []
		for element in elements[2...] {
			makeAddlFields.append(element)
		}
		try! self.init(NOSTR_tag_namefield:makeName, NOSTR_tag_indexfield:makeIndexField, NOSTR_tag_addlfields:makeAddlFields)
	}
}
