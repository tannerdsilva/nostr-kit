/// a type that claims to directly correlate with a HRP value for the bech32 encoding & decoding schemes.
public protocol NOSTR_bech32_hrp {
	/// the human readable part of the bech32 encoding. this is the prefix that is used to identify the encoding type.
	static var NOSTR_bech32_hrp:String { get }

	/// decodes a bech32 encoded string into a byte array. this is used to validate the HRP and to get to the underlying byte contents.
	/// - NOTE: default implementation provided.
	static func NOSTR_bech32_hrp_decode(NOSTR_bech32_encoded:String) throws -> [UInt8]
}

// default implementations for the protocol
extension NOSTR_bech32_hrp {
	// returns the bech32 encoded string representation of the raw value
	public static func NOSTR_bech32_hrp_decode(NOSTR_bech32_encoded:String) throws -> [UInt8] {
		let decoded = try Bech32.decode(NOSTR_bech32_encoded)
		guard decoded.hrp.lowercased() == Self.NOSTR_bech32_hrp else {
			throw Bech32.Errors.InvalidBech32HRP(expectedHRP:Self.NOSTR_bech32_hrp, foundHRP:Self.NOSTR_bech32_hrp, foundData:decoded.data)
		}
		return decoded.data
	}
}
