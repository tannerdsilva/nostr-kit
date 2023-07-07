extension Event.Tag {
	/// captures the two types of event tags that require a practical distinction in nostr.
	/// for more info as to why this is necessary, see the NIP-12 proposal.
	public enum Name {
		/// represents a # (dynamic) tag of a specific character
		case generic(Character)

		/// represents a named tag of a non-distinct type
		case name(String)
	}
}

extension Event.Tag.Name:NOSTR_tag_namefield {
	/// this is the "primary truth" initializer for this type.
	public init<N>(NOSTR_tag_namefield: N) throws where N : NOSTR_tag_namefield {
		let value = NOSTR_tag_namefield.NOSTR_tag_namefield
		if value.count == 2 && value.first! == "#" && value.last!.isLetter == true {
			self = .generic(value.lowercased().last!)
		} else {
			guard value.count > 0 else {
				throw ZeroLengthError()
			}
			self = .name(value)
		}
	}
	public var NOSTR_tag_namefield:String {
		switch self {
			case .generic(let char):
				return "#\(char)"
			case .name(let name):
				return name
		}
	}
}

// equatable conformance
extension Event.Tag.Name:Equatable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		switch (lhs, rhs) {
			case (.generic(let lchar), .generic(let rchar)):
				return lchar == rchar
			case (.name(let lname), .name(let rname)):
				return lname == rname
			default:
				return false
		}
	}
}

// hashable conformance
extension Event.Tag.Name:Hashable {
	public func hash(into hasher:inout Hasher) {
		switch self {
			case .generic(let char):
				hasher.combine(0)
				hasher.combine(char)
			case .name(let name):
				hasher.combine(1)
				hasher.combine(name)
		}
	}
}

extension Event.Tag.Name {
	/// thrown when a tag name of zero length is encountered
	public struct ZeroLengthError:Swift.Error {}

	/// thrown when an expected dynamic tag key is initialized with a string of length greater than 1 or # + 1.
	public struct DynamicOverflowError:Swift.Error {
		public let encounteredValue:String
		public init(encounteredValue:String) {
			self.encounteredValue = encounteredValue
		}
	}
}