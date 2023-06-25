// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import RAW

/// a public key representation of a nostr key struct
public typealias PublicKey = Key

/// a secret key representation of a nostr key struct
public typealias SecretKey = Key

@frozen
public struct Key {
	public enum Error: Swift.Error {
		/// thrown when decoding using ``Decodable` protocol. specifically thrown when a string value is successfully extraced froma single value container, but the string is not a valid hex-encoded string.
		case encodedStringInvalid

		/// thrown when trying to initialize a Key from a npub or nsec string.
		case invalidBech32HRP(String)

		/// thrown when the data returned from the bech32 decoder is longer than the size of the Key struct (32 bytes)
		case invalidBech32DataLength(size_t)

		/// thrown when the data returned from the bech32 decoder is shorter or longer than the size of the Key struct (32 bytes)
		case invalidKeyLength(size_t)
	}

	// 32 byte static buffer
	internal var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	// initialize a null structure
	internal init() {}

	/// initialize a key from an npub encoded string
	/// - parameter npub: the npub encoded string to decode
	public init(npub:String) throws {
		let decoded = try Bech32.decode(npub)
		guard decoded.hrp.lowercased() == "npub" else {
			throw Error.invalidBech32HRP(decoded.hrp)
		}
		guard decoded.data.count == MemoryLayout<Self>.size else {
			throw Error.invalidBech32DataLength(decoded.data.count)
		}
		self = decoded.data.asRAW_val { rawVal in 
			return Self.init(rawVal)! /* this is safe because length has already been validated */
		}
	}

	/// returns the bech32 encoded public key representation of this key
	public func npubString() -> String {
		return self.asRAW_val({ rawVal in
			return Bech32.encode(hrp:"npub", rawVal)
		})
	}

	/// initialize a key from an nsec encoded string
	/// - parameter nsec: the nsec encoded string to decode
	public init(nsec:String) throws {
		let decoded = try Bech32.decode(nsec)
		guard decoded.hrp.lowercased() == "nsec" else {
			throw Error.invalidBech32HRP(decoded.hrp)
		}
		guard decoded.data.count == MemoryLayout<Self>.size else {
			throw Error.invalidBech32DataLength(decoded.data.count)
		}
		self = decoded.data.asRAW_val { rawVal in 
			return Self.init(rawVal)! /* this is safe because length has already been validated */
		}
	}

	/// returns the bech32 encoded private key representation of this key
	public func nsecString() -> String {
		return self.asRAW_val({ rawVal in
			return Bech32.encode(hrp:"nsec", rawVal)
		})
	}
}

extension Key:RAW_convertible {
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
		return try withUnsafePointer(to: bytes, { unsafePointer in
			var val = RAW_val(mv_size:MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
			return try valFunc(&val)
		})
	}
}

extension Key:RAW_comparable {
	// Lexigraphical sorting here
	public static let rawCompareFunction:@convention(c) (UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 = { a, b in
		let aData = a!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		let bData = b!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		
		let minLength = min(a!.pointee.mv_size, b!.pointee.mv_size)
		let comparisonResult = memcmp(aData, bData, minLength)

		if comparisonResult != 0 {
			return Int32(comparisonResult)
		} else {
			// If the common prefix is the same, compare their lengths.
			return Int32(a!.pointee.mv_size) - Int32(b!.pointee.mv_size)
		}
	}
}

/// LosslessStringConvertible conformance 
/// - based on a hex-encoded representation of the key bytes
extension Key:LosslessStringConvertible {
	/// implements a hex-encoded representation of the key bytes
	public var description:String {
		get {
			self.asRAW_val({
				return Hex.encode($0, lowercaseOutput:true)
			})
		}
	}

	/// initialize a key from a hex-encoded representation of the key bytes
	public init?(_ description:String) {
		let asBytes:[UInt8]
		do {
			asBytes = try Hex.decode(description)
		} catch {
			return nil
		}
		guard asBytes.count == MemoryLayout<Self>.size else {
			return nil
		}
		let makeKey = asBytes.asRAW_val { rv in
			return Self.init(rv)
		}
		guard makeKey != nil else {
			return nil
		}
		self = makeKey!
	}
}

extension Key:Codable {
	// decode implementation
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let asString = try container.decode(String.self)
		guard let asKey = Self(asString) else {
			throw Error.encodedStringInvalid
		}
		self = asKey
	}
	// encode implementation
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}
}

extension Key:Hashable, Equatable, Comparable {
	// Equatable
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) == 0
			})
		})
	}
	
	// Comparable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) < 0
			})
		})
	}

	// Hashable
	public func hash(into hasher:inout Hasher) {
		self.asRAW_val({ RAWVal in
			hasher.combine(RAWVal)
		})
	}
}
