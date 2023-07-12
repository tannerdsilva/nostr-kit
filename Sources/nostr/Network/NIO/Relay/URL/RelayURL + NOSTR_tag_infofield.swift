// (c) tanner silva 2023. all rights reserved.

extension Relay.URL:NOSTR_tagged {
    public static var NOSTR_tagged_name: Event.Tag.Name {
        return "r"
    }

    public var NOSTR_tag_indexfield: String {
        return self.description
    }

    public var NOSTR_tag_addlfields: [any NOSTR_tag_addlfield] {
        return []
    }

	public init(NOSTR_tag_index: String, NOSTR_tag_addlfields: [any NOSTR_tag_addlfield]) throws {
		let url = Self(NOSTR_tag_index)
		self = url
	}
}