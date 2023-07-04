public typealias NOSTR_Date_impl = NOSTR_Date_expl

public protocol NOSTR_Date_expl {
	associatedtype NOSTR_DateInterval_Type:Strideable where NOSTR_DateInterval_Type.Stride:SignedNumeric & Comparable
	var unixInterval:NOSTR_DateInterval_Type { get }
	init(unixInterval:NOSTR_DateInterval_Type)
}