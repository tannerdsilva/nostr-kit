extension Relay.URL:NOSTR_tagged_type {
    public init(NOSTR_tag_indexfield:String, NOSTR_tag_addlfields: [any NOSTR_tag_addlfield]) throws {
        self = Relay.URL(NOSTR_tag_indexfield)
    }

    public static var NOSTR_tagged_type_namefield: String {
        return "r"
    }
	public typealias NOSTR_tagged_type_indexfield_TYPE = String

	public var NOSTR_tag_infofield:String {
		return self.description
	}
}