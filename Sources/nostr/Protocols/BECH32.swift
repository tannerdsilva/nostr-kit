// (c) tanner silva 2023. all rights reserved.

import RAW

/// a type definition for bech32 encoding. does not actually encode or decode anything, just provides a type definition for the encoding.
/// - used primarily for implementing the `NOSTR_bech32_convertible` protocol.
public struct NOSTR_bech32_TL_DEF {
	let type:UInt8
	let length:UInt8?
}

/// defines a stricter type of NOSTR_bech32 that converts directly to and from a raw value type. this allows the protocol to implement more of the encoding/decoding logic.
public protocol NOSTR_bech32_raw:RAW_convertible, NOSTR_bech32 {}

extension NOSTR_bech32_raw {
	/// the raw encodings do not have any type/length configuration information
	public static var NOSTR_bech32_TL_DEF:NOSTR_bech32_TL_DEF? {
		return nil
	}
	/// initialize from raw bytes.
	public init(NOSTR_bech32:String) throws {
		let decoded = try Bech32.decode(NOSTR_bech32)
		guard decoded.hrp.lowercased() == Self.NOSTR_bech32_hrp else {
			throw Bech32.Errors.InvalidBech32HRP(expectedHRP:Self.NOSTR_bech32_hrp, foundHRP:Self.NOSTR_bech32_hrp, payload:NOSTR_bech32)
		}
		self = decoded.data.asRAW_val { rawVal in 
			return Self.init(rawVal)! /* this is safe because length has already been validated */
		}
	}
	/// returns the bech32 encoded string representation of the raw value.
	public func NOSTR_bech32() -> String {
		return self.asRAW_val({ rawVal in
			return Bech32.encode(hrp:Self.NOSTR_bech32_hrp, rawVal)
		})
	}
}

public protocol NOSTR_bech32 {
	static var NOSTR_bech32_hrp:String { get }
	static var NOSTR_bech32_TL_DEF:NOSTR_bech32_TL_DEF? { get }
	init(NOSTR_bech32:String) throws
	func NOSTR_bech32() -> String
}

public extension Bech32.Errors {
	/// thrown by the `NOSTR_bech32` protocol and its variants to signal that the parsed HRP does not match the HRP that is expected with the given type.
	struct InvalidBech32HRP:Swift.Error {
		public let expectedHRP:String
		public let foundHRP:String
		public let payload:String
	}
}