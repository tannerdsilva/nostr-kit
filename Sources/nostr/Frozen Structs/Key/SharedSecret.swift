// (c) tanner silva 2023. all rights reserved.

import secp256k1
import RAW

@frozen public struct SharedSecret {
	// 32 byte static buffer
	internal var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

extension SharedSecret {
	public init(ourSecret:SecretKey, theirPublicKey:PublicKey) throws {
		let secretBytes = ourSecret.asRAW_val {
			return Array($0)
		}
		var publicBytes = theirPublicKey.asRAW_val {
			return Array($0)
		}
		publicBytes.insert(2, at:0)
		var pubkey = secp256k1_pubkey()
		guard secp256k1_ec_pubkey_parse(secp256k1.Context.raw, &pubkey, publicBytes, publicBytes.count) == 1 else {
			throw Error.invalidPublicKey
		}
		// try withUnsafeMutablePointer(to:&bytes) { ptr in
			guard secp256k1_ecdh(secp256k1.Context.raw, &bytes, &pubkey, secretBytes, { (output, x32, _, _) in memcpy(output, x32, 32); return 1; }, nil) == 1 else {
				throw Error.invalidPublicKey
			}
		// }
	}
}

extension SharedSecret:RAW_convertible {
	/// initialize from raw bytes.
	/// - this initializer will return nil if the size of the raw bytes is not equal to the size of the Key struct (32 bytes)
	/// - this initializer will NEVER fail if the input data is exactly 32 bytes
	public init?(_ value: RAW_val) {
		guard value.mv_size == MemoryLayout<Self>.size else {
			return nil
		}
		_ = memcpy(&bytes, value.mv_data, MemoryLayout<Self>.size)
	}
	public func asRAW_val<R>(_ valFunc: (inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:bytes, { unsafePointer in
			var val = RAW_val(mv_size:MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
			return try valFunc(&val)
		})
	}
}

extension SharedSecret:RAW_comparable {
	// Lexigraphical sorting here
	public static let rawCompareFunction:@convention(c) (UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 = { a, b in
		let aData = a!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		let bData = b!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		
		let minLength = Swift.min(a!.pointee.mv_size, b!.pointee.mv_size)
		let comparisonResult = memcmp(aData, bData, minLength)

		if comparisonResult != 0 {
			return Int32(comparisonResult)
		} else {
			// If the common prefix is the same, compare their lengths.
			return Int32(a!.pointee.mv_size) - Int32(b!.pointee.mv_size)
		}
	}
}
