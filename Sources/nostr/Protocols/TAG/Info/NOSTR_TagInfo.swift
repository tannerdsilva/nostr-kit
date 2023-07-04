public protocol NOSTR_tag_info:ExpressibleByArrayLiteral, Collection where Element == any NOSTR_tag_info_field {
	/// if a nostr tag is represented as an unkeyed container of stringlike objects, this is the primitive type that defines the boundaries around the "stringlike-ness"
	associatedtype NOSTR_TYPE_tag_info:LosslessStringConvertible

	/// initialize from a string representation of the nostr tag name.
	init<C>(NOSTR_tag_info:C) throws where C:Collection, C.Element == any NOSTR_tag_info_field
}
