#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public protocol NOSTR_tag:ExpressibleByArrayLiteral, Collection where Element == any LosslessStringConvertible {
	associatedtype NOSTR_TYPE_tag_name:NOSTR_tag_name
	associatedtype NOSTR_TYPE_tag_info:Collection where NOSTR_TYPE_tag_info.Element == any NOSTR_tag_info_field

	/// represents the nostr tag name as a string representation.
	var NOSTR_tag_name:NOSTR_TYPE_tag_name { get }

	var NOSTR_tag_info:NOSTR_TYPE_tag_info { get }

	/// initialize from a string representation of the nostr tag name.
	init(NOSTR_tag_name:NOSTR_TYPE_tag_name, NOSTR_tag_info:NOSTR_TYPE_tag_info)
}

extension NOSTR_tag where NOSTR_TYPE_tag_name:LosslessStringConvertible, NOSTR_TYPE_tag_info:Collection, NOSTR_TYPE_tag_info.Element == any NOSTR_tag_info_field {
	/// implement expressible by array literal.
	public init(arrayLiteral elements:Element...) {
		let getElement = elements[0]
		let makeName = NOSTR_TYPE_tag_name(NOSTR_tag_name:elements[0])
		self.init(NOSTR_tag_name:NOSTR_TYPE_tag_name(NOSTR_tag_name:elements[0].description), NOSTR_tag_info:elements[1...])
	}
}
let myTag:NOSTR_tag = ["#a", "b", "c"]