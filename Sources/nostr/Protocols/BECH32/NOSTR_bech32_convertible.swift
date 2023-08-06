/// a type that can encode to a bech32 string.
public protocol NOSTR_bech32_encodable {
	func NOSTR_bech32_encode(hrp:String) -> String
}

/// a type that can decode from a bech32 string.
public protocol NOSTR_bech32_decodable {
	/// decode from a bech32 encoded string.
	init(NOSTR_bech32_encoded:String) throws
}

public typealias NOSTR_bech32_convertible = NOSTR_bech32_encodable & NOSTR_bech32_decodable