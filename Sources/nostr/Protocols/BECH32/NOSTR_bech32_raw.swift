import RAW

/// defines a type of NOSTR_bech32_convertible that converts directly to and from a raw value type. this allows the protocol to implement more of the encoding/decoding logic.
/// - required protocols:
///		- `NOSTR_bech32_hrp`: this is required becuase types that take exclusive control of the encoding body content must define their own HRP.
///		- `RAWB32_convertible`: this is required because the type must be able to convert to and from a raw value that goes in the bech32 encoding buffer.
public protocol NOSTR_bech32_raw:RAW_convertible, NOSTR_bech32_hrp {}
extension NOSTR_bech32_raw {
	/// initialize from raw bytes.
	public init(NOSTR_bech32_encoded NOSTR_bech32:String) throws {
		let decoded = try Self.NOSTR_bech32_hrp_decode(NOSTR_bech32_encoded:NOSTR_bech32)
		self = decoded.asRAW_val { rawVal in 
			return Self.init(rawVal)! /* this is safe because length has already been validated */
		}
	}
	/// returns the bech32 encoded string representation of the raw value.
	public func NOSTR_bech32_encode() -> String {
		return self.asRAW_val({ rawVal in
			return Bech32.encode(hrp:Self.NOSTR_bech32_hrp, rawVal)
		})
	}
}
