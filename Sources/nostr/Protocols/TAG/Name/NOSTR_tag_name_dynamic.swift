public protocol NOSTR_tag_namefield_generic:NOSTR_tag_namefield where NOSTR_tag_namefield_TYPE == String {
	associatedtype NOSTR_tag_namefield_TYPE = String
	
	var NOSTR_tag_namefield_generic:Character { get }

	init(NOSTR_tag_namefield_generic:Character) throws
}

extension NOSTR_tag_namefield_generic where Self:NOSTR_tag_namefield, NOSTR_tag_namefield_TYPE == String {
	public var NOSTR_tag_namefield:NOSTR_tag_namefield_TYPE {
		return "\(self)"
	}
	public init(NOSTR_tag_namefield:String) throws {
		guard NOSTR_tag_namefield.count > 0 else {
			throw nostr.Event.Tag.Name.ZeroLengthError()
		}
		try self.init(NOSTR_tag_namefield_generic:NOSTR_tag_namefield.last!)
	}
}

extension Character:NOSTR_tag_namefield_generic {
    public var NOSTR_tag_namefield_generic:Character {
        return self
    }

    public init(NOSTR_tag_namefield_generic:Character) throws {
		self = NOSTR_tag_namefield_generic
    }
}