// (c) tanner silva 2023. all rights reserved.

extension Event {
	public typealias Tags = Array<any NOSTR_tag>
}

extension Event.Tags {
	/// converts an array of tags into a dictionary of tag names and tag indices.
	internal func asNamedDictionary() -> [String:String] {
		var dict:[String:String] = [:]
		for tag in self {
			dict[tag.NOSTR_tag_namefield.NOSTR_tag_name] = tag.NOSTR_tag_indexfield.NOSTR_tag_index
		}
		return dict
	}
}