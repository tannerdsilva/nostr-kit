// (c) tanner silva 2023. all rights reserved.

/// allows an instance of a specific Swift type to convey itself explicitly as a tag instance.
public protocol NOSTR_tag:ExpressibleByArrayLiteral, Collection where Element == String, ArrayLiteralType == String {
	associatedtype Element = String // element must be string literal since any of the sub protocols that can be found in the body of this type.
	associatedtype ArrayLiteralType = String
	
	associatedtype NOSTR_tag_name_TYPE:NOSTR_tag_name = nostr.Event.Tag.Name
	associatedtype NOSTR_tag_index_TYPE:NOSTR_tag_index = String

	/// the instance variable that represents the name for this tag instance.
	var NOSTR_tag_namefield:NOSTR_tag_name_TYPE { get }

	/// the instance variable that represents the index value for this tag instance.
	var NOSTR_tag_indexfield:NOSTR_tag_index_TYPE { get }

	/// the instance variable that represents any additional values for this intance. 
	var NOSTR_tag_addlfields:[any NOSTR_tag_addlfield] { get }

	/// initialize a tag from given values of their specific name, index, and (optionally) additional types.
	init(NOSTR_tag_name:NOSTR_tag_name_TYPE, NOSTR_tag_index:NOSTR_tag_index_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws
}

// array will implement the NOSTR_tag protocol if its element type is a string. it is assumed that the first element is of nonzero length and the second value exists.
extension Array:NOSTR_tag where Element == String {
	public init(NOSTR_tag_name: String, NOSTR_tag_index: String, NOSTR_tag_addlfields: [any NOSTR_tag_addlfield]) throws {
		var buildArray = [String]()
		buildArray.append(NOSTR_tag_name)
		buildArray.append(NOSTR_tag_index)
		for addlfield in NOSTR_tag_addlfields {
			buildArray.append(addlfield.NOSTR_tag_addlfield)
		}
		self = buildArray
	}

	public var NOSTR_tag_namefield:String {
		return self[0]
	}

	public var NOSTR_tag_indexfield:String {
		return self[1]
	}

	public var NOSTR_tag_addlfields:[any NOSTR_tag_addlfield] {
		return Array(self[2...])
	}
}

// everyone gets a default implementation of the encodable protocol
extension NOSTR_tag {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(self.NOSTR_tag_namefield.NOSTR_tag_name)
		try container.encode(self.NOSTR_tag_indexfield.NOSTR_tag_index)
		for addlfield in self.NOSTR_tag_addlfields {
			try container.encode(addlfield.NOSTR_tag_addlfield)
		}
		fatalError()
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
		fatalError()
		try self.init(NOSTR_tag_name:NOSTR_tag_name_TYPE(NOSTR_tag_name:namefield), NOSTR_tag_index:NOSTR_tag_index_TYPE(NOSTR_tag_index:indexfield), NOSTR_tag_addlfields:addlfields)
	}
}

// everyone gets a default implementation of Collection
extension NOSTR_tag {
	public var startIndex:Int {
		return 0
	}
	public var endIndex:Int {
		return 2 + self.NOSTR_tag_addlfields.count
	}
	public subscript(position:Int) -> String {
		switch position {
		case 0:
			return self.NOSTR_tag_namefield.NOSTR_tag_name
		case 1:
			return self.NOSTR_tag_indexfield.NOSTR_tag_index
		default:
			return self.NOSTR_tag_addlfields[position - 2].NOSTR_tag_addlfield
		}
	}
	public subscript(bounds:Range<Int>) -> ArraySlice<String> {
		var buildArrSlice = ArraySlice<String>()
		// add the namefield if the bounds include the first index
		if bounds.contains(0) {
			buildArrSlice.append(self.NOSTR_tag_namefield.NOSTR_tag_name)
		}
		// add the indexfield if the bounds include the second index
		if bounds.contains(1) {
			buildArrSlice.append(self.NOSTR_tag_indexfield.NOSTR_tag_index)
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
extension NOSTR_tag {
	public init(arrayLiteral elements:String...) {
		let makeName = try! NOSTR_tag_name_TYPE(NOSTR_tag_name:elements[0])
		let makeIndexField = try! NOSTR_tag_index_TYPE(NOSTR_tag_index:elements[1])
		var makeAddlFields:[any NOSTR_tag_addlfield] = []
		for element in elements[2...] {
			makeAddlFields.append(element)
		}
		try! self.init(NOSTR_tag_name:makeName, NOSTR_tag_index:makeIndexField, NOSTR_tag_addlfields:makeAddlFields)
	}
}
