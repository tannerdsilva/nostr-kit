// (c) tanner silva 2023. all rights reserved.

import cnostr

// event tag
extension Event {
	/// an event tag. used to attach various reference types and schemes to events.
	/// the native expression type is an array of string,s, where the first element is the name.
	/// there are special cases where a tag can also encode and decode from a dictionary.
	/// - examples of tags include:
	/// 	- as attached to nostr events
	/// 		- `["challenge", "some-challenge-string"]`
	/// 		- `["auth", "some-auth-token"]`
	/// 		- `["#p", "dynamic tag name"]`
	///		- as attached to relay filters (dynamic tags only)
	///			- `{"#p", "dynamic tag name"...}`
	/// - note: tags cannot be empty, and must have a name of at least one character.
	public struct Tag {
		/// the type of tag.
		public let name:Name
		/// additional info associated with the tag
		public let index:String
		/// initialize from a tag name and tag info
		public let additionalInfo:[String]
	}
}

extension Event.Tag:NOSTR_tag {
	/// the type of tag.
	public typealias NOSTR_tag_name_TYPE = Event.Tag.Name
	/// additional info associated with the tag
	public typealias NOSTR_tag_index_TYPE = String

	/// initialize from a tag name and tag info
	public init(NOSTR_tag_name:NOSTR_tag_name_TYPE, NOSTR_tag_index:NOSTR_tag_index_TYPE, NOSTR_tag_addlfields:[any NOSTR_tag_addlfield]) throws {
		self.name = NOSTR_tag_name
		self.index = NOSTR_tag_index
		self.additionalInfo = NOSTR_tag_addlfields.map { $0.NOSTR_tag_addlfield }
	}

	/// the type of tag.
	public var NOSTR_tag_namefield:NOSTR_tag_name_TYPE {
		return self.name
	}
	/// additional info associated with the tag
	public var NOSTR_tag_indexfield:NOSTR_tag_index_TYPE {
		return self.index
	}
	/// additional info associated with the tag
	public var NOSTR_tag_addlfields:[any NOSTR_tag_addlfield] {
		return self.additionalInfo
	}
}

extension Event.Tag {
	/// an error that is thrown when a represented tag array is empty
	public struct EmptyContainerError:Swift.Error {}
}