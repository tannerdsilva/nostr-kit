public typealias NOSTR_Event_impl = NOSTR_Event_expl & Codable

public protocol NOSTR_Event_expl:Codable {
	
	associatedtype NOSTR_EventKind_Type:Hashable, Equatable, Comparable, SignedInteger where NOSTR_EventKind_Type:RawRepresentable, NOSTR_EventKind_Type.RawValue == Int64
	
	associatedtype NOSTR_DynamicTags_Type:Sequence where NOSTR_DynamicTags_Type.Element == any NOSTR_Tag_expl

	associatedtype NOSTR_EventDate_Type:NOSTR_Date_expl

	/// the unique identifier for the event
	var uid:Event.UID { get }
	/// the kind of event
	var kind:NOSTR_EventKind_Type { get }
	/// the date the event was created
	var date:NOSTR_EventDate_Type { get }
	/// the public key of the author of the event
	var author:nostr.Key { get }
	/// the dynamic tags associated with the event
	var dynamicTags:NOSTR_DynamicTags_Type { get }
	/// the content of the event
	var content:String { get }

	/// initialize from a uid, kind, date, author, dynamic tags, and content
	init(uid:Event.UID, kind:NOSTR_EventKind_Type, date:Date, author:nostr.Key, dynamicTags:NOSTR_DynamicTags_Type, content:String)

}