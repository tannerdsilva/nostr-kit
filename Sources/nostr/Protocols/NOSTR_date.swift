/// a protocol for types that represent a date
public protocol NOSTR_date {
	/// the date as a unix timestamp
	var NOSTR_date_unixInterval:UInt64 { get }

	/// initialize from a unix timestamp
	init(NOSTR_date_unixInterval:UInt64)

	/// initialize with the current time
	init()
}