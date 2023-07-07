import RAW

public struct NOSTR_bech32_TL_DEF {
	let type:UInt8
	let length:UInt8?
}

public protocol NOSTR_bech32_raw_convertible:RAW_convertible, NOSTR_bech32_convertible {
	static var NOSTR_bech32_hrp:String { get }
	init(NOSTR_bech32_raw_convertible:String) throws
	func NOSTR_bech32_raw_convertible() -> String
}

public protocol NOSTR_bech32_convertible {
	static var NOSTR_bech32_hrp:String { get }
	static var NOSTR_bech32_TL_DEF:NOSTR_bech32_TL_DEF? { get }
	init(NOSTR_bech32_convertible:String) throws
	func NOSTR_bech32_convertible() -> String
}