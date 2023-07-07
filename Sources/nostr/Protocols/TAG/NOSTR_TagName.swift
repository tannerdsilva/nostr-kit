public protocol NOSTR_tagged_type {
	associatedtype NOSTR_tagged_type_namefield_TYPE:NOSTR_tag_namefield = nostr.Event.Tag.Name
	associatedtype NOSTR_tagged_type_indexfield_TYPE:NOSTR_tag_indexfield
	static var NOSTR_tagged_type_namefield:NOSTR_tagged_type_namefield_TYPE { get }
	init(NOSTR_tag_indexfield:NOSTR_tagged_type_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

extension NOSTR_tagged_inst where Self:NOSTR_tagged_type, NOSTR_tagged_type_namefield_TYPE == NOSTR_tag_namefield_TYPE{
	public var NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE {
		return Self.NOSTR_tagged_type_namefield
	}
	public init(NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws {
		try self.init(NOSTR_tag_namefield:Self.NOSTR_tagged_type_namefield, NOSTR_tag_indexfield:NOSTR_tag_indexfield, NOSTR_tag_addlfields:NOSTR_tag_addlfields)
	}
}

extension NOSTR_tag_indexfield where Self:NOSTR_tagged_type, NOSTR_tagged_type_indexfield_TYPE == Self {
	public init(NOSTR_tag_indexfield:NOSTR_tagged_type_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws {
		self = try Self(NOSTR_tag_indexfield:NOSTR_tag_indexfield.NOSTR_tag_indexfield)
	}
}

public protocol NOSTR_tagged_inst:ExpressibleByArrayLiteral, Codable, Collection where Element == String, ArrayLiteralType == String {
	associatedtype Element = String
	associatedtype ArrayLiteralType = String
	associatedtype NOSTR_tag_namefield_TYPE:NOSTR_tag_namefield = nostr.Event.Tag.Name
	associatedtype NOSTR_tag_indexfield_TYPE:NOSTR_tag_indexfield = String

	var NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE { get }
	var NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE { get }
	var NOSTR_tag_addlfields:[any NOSTR_tag_addlfield] { get }

	init(NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE, NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

// everyone gets a default implementation of the encodable protocol
extension NOSTR_tagged_inst {
	init<T>(_ tag: T) throws where T:NOSTR_tagged_inst {
		let makeName = try NOSTR_tag_namefield_TYPE(NOSTR_tag_namefield:tag.NOSTR_tag_namefield.NOSTR_tag_namefield)
		let makeIndex = try NOSTR_tag_indexfield_TYPE(NOSTR_tag_indexfield:tag.NOSTR_tag_indexfield)
		let makeAddlfields = tag.NOSTR_tag_addlfields
		try self.init(NOSTR_tag_namefield:makeName, NOSTR_tag_indexfield:makeIndex, NOSTR_tag_addlfields:makeAddlfields)
	}
}
extension NOSTR_tagged_inst {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(self.NOSTR_tag_namefield.NOSTR_tag_namefield)
		try container.encode(self.NOSTR_tag_indexfield.NOSTR_tag_indexfield)
		for addlfield in self.NOSTR_tag_addlfields {
			try container.encode(addlfield.NOSTR_tag_addlfield)
		}
	}
	public init(from decoder: Decoder) throws {
		var container = try decoder.unkeyedContainer()
		let namefield = try container.decode(String.self)
		let indexfield = try container.decode(String.self)
		var addlfields = [any NOSTR_tag_addlfield]()
		while !container.isAtEnd {
			let addlfield = try container.decode(String.self)
			addlfields.append(addlfield)
		}
		try self.init(NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE(NOSTR_tag_namefield:namefield), NOSTR_tag_indexfield:NOSTR_tag_indexfield_TYPE(NOSTR_tag_indexfield:indexfield), NOSTR_tag_addlfields:addlfields)
	}
}

// everyone gets a default implementation of Collection
extension NOSTR_tagged_inst {
	public var startIndex:Int {
		return 0
	}
	public var endIndex:Int {
		return 2 + self.NOSTR_tag_addlfields.count
	}
	public subscript(position:Int) -> String {
		switch position {
		case 0:
			return self.NOSTR_tag_namefield.NOSTR_tag_namefield
		case 1:
			return self.NOSTR_tag_indexfield.NOSTR_tag_indexfield
		default:
			return self.NOSTR_tag_addlfields[position - 2].NOSTR_tag_addlfield
		}
	}
	public subscript(bounds:Range<Int>) -> ArraySlice<String> {
		var buildArrSlice = ArraySlice<String>()
		// add the namefield if the bounds include the first index
		if bounds.contains(0) {
			buildArrSlice.append(self.NOSTR_tag_namefield.NOSTR_tag_namefield)
		}
		// add the indexfield if the bounds include the second index
		if bounds.contains(1) {
			buildArrSlice.append(self.NOSTR_tag_indexfield.NOSTR_tag_indexfield)
		}
		for curAddl in self.NOSTR_tag_addlfields {
			let curIndex = buildArrSlice.count
			if bounds.contains(curIndex) {
				buildArrSlice.append(curAddl.NOSTR_tag_addlfield)
			}
		}
		return buildArrSlice
	}
	public func index(after i:Int) -> Int {
		return i + 1
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
