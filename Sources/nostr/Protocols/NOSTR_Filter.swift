public typealias NOSTR_Filter_impl = NOSTR_Filter_expl & Codable

public protocol NOSTR_Filter_expl:Codable {

	associatedtype NOSTR_EventKind_Type:Hashable, Equatable, Comparable, SignedInteger where NOSTR_EventKind_Type:RawRepresentable, NOSTR_EventKind_Type.RawValue == Int64
	associatedtype NOSTR_DynamicTags_Type:Sequence where NOSTR_DynamicTags_Type.Element == any NOSTR_Tag_expl

	/// event uids to filter by
	var uids:Set<Event.UID>? { get }
	/// event kinds to filter by
	var kinds:Set<NOSTR_EventKind_Type>? { get }
	/// retruned events will be limited to those that follow this date
	var since:Date? { get }
	/// returned events will be limited to those that precede this date
	var until:Date? { get }
	/// limit the number of events returned
	var limit:UInt32? { get }
	/// returned events must be authored by one of these public keys
	var authors:Set<nostr.Key>? { get }
	/// dynamic tags to filter by
	var dynamicTags:NOSTR_DynamicTags_Type? { get }

}