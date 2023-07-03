// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

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
	public struct Tag:NOSTR_Tag_impl {
		/// the type of tag.
		public let NOSTR_TagName:Name
		/// additional info associated with the tag
		public let NOSTR_TagInfo:[String]

		/// initialize from a tag name and tag info
		public init(NOSTR_TagName:Name, NOSTR_TagInfo:[String]) {
			self.NOSTR_TagName = NOSTR_TagName
			self.NOSTR_TagInfo = NOSTR_TagInfo
		}
	}
}

extension Event.Tag {
	/// an error that is thrown when a represented tag array is empty
	public struct EmptyContainerError:Swift.Error {}
}