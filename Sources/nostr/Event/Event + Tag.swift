// event tag
extension Event {
	public struct Tag {
		public let kind:Kind
		public let info:[String]
	}
}

// event tag - additional implementations
extension Event.Tag {
	/// create an event tag from a string
	public static func fromPublicKey(_ pubkey:PublicKey) throws -> Event.Tag {
		return Event.Tag(kind:.pubkey, info:[pubkey.description])
	}
	public var count:Int {
		return info.count + 1
	}
	public init(_ array:[String]) {
		self.init(kind:Kind(array[0]), info:Array(array[1...]))
	}
	public subscript(_ index:Int) -> String {
		get {
			if index == 0 {
				return self.kind.description
			} else {
				return self.info[index - 1]
			}
		}
	}
	public func toArray() -> [String] {
		return [self.kind.description] + self.info
	}
}

// event tag - codable
extension Event.Tag:Codable {
	// decode implementation
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let asArray = try container.decode([String].self)
		self.init(asArray)
	}
	// encode implementation
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.toArray())
	}
}

// event tag kind
extension Event.Tag {
	public enum Kind {
		case event
		case pubkey
		case unknown(String)
	}
}

// event tag kind - codable
extension Event.Tag.Kind:Codable {
	// decode implementation
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let asString = try container.decode(String.self)
		self.init(asString)
	}
	// encode implementation
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}
}

// event tag kind - lossless string convertible
extension Event.Tag.Kind:LosslessStringConvertible {
	public var description:String {
		get {
			switch self {
				case .event:
					return "e"
				case .pubkey:
					return "p"
				case .unknown(let unknown):
					return unknown
			}
		}
	}

	public init(_ description:String) {
		switch description {
			case "e":
				self = .event
			case "p":
				self = .pubkey
			default:
				self = .unknown(description)
		}
	}
}

// event tag kind - hashable, equatable, comparable
extension Event.Tag.Kind:Hashable, Equatable, Comparable {
	// Equatable
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.description == rhs.description
	}
	
	// Comparable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.description < rhs.description
	}

	// Hashable
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.description)
	}
}