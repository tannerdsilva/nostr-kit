extension Event.Tag {
	enum Key:Hashable, Equatable {

		case dynamic(Character)
		case name(String)

		internal init(_ string:String) {
			if string.count == 2 && string.first! == "#" && string.last!.isLetter == true {
				self = .dynamic(string.last!)
			} else {
				self = .name(string)
			}
		}

		public func hash(into hasher:inout Hasher) {
			switch self {
				case .dynamic(let char):
					hasher.combine(0)
					hasher.combine(char)
				case .name(let name):
					hasher.combine(1)
					hasher.combine(name)
			}
		}

		static func == (lhs:Self, rhs:Self) -> Bool {
			switch (lhs, rhs) {
				case (.dynamic(let lchar), .dynamic(let rchar)):
					return lchar == rchar
				case (.name(let lname), .name(let rname)):
					return lname == rname
				default:
					return false
			}
		}
	}
}


extension Event.Tag.Key:CodingKey {
    public var stringValue: String {
        switch self {
			case .dynamic(let char):
				return "#\(char)"
			case .name(let name):
				return name
		}
    }

    public init?(stringValue: String) {
		self.init(stringValue)
    }

    public var intValue: Int? {
        return nil
    }

    public init?(intValue: Int) {
        return nil
    }

	
}