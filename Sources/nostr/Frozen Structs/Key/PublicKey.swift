// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import RAW

@frozen public struct PublicKey {
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
}

extension PublicKey:RAW_convertible {
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

extension PublicKey:RAW_comparable {
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

extension PublicKey:HEX_convertible {
	public var hexEncodedString:String {
		get {
			self.asRAW_val({
				return Hex.encode($0, lowercaseOutput:true)
			})
		}
	}

	public init(hexEncodedString: String) throws {
		let asBytes = try Hex.decode(hexEncodedString)
		guard asBytes.count == MemoryLayout<Self>.size else {
			throw Error.invalidKeyLength(asBytes.count)
		}
		let makeKey = asBytes.asRAW_val { rv in
			return Self.init(rv)!
		}
		self = makeKey
	}
}

/// LosslessStringConvertible conformance 
/// - based on a hex-encoded representation of the key bytes
extension PublicKey:CustomStringConvertible {
	/// implements a hex-encoded representation of the key bytes
	public var description:String {
		return self.hexEncodedString
	}
}

extension PublicKey:Codable {
	// decode implementation
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		let asString = try container.decode(String.self)
		self = try Self(hexEncodedString:asString)
	}
	// encode implementation
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.hexEncodedString)
	}
}

extension PublicKey:Hashable, Equatable, Comparable {
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

extension PublicKey {
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
}

extension nostr.PublicKey:NOSTR_tag_indexfield {
    public init<I>(NOSTR_tag_indexfield: I) throws where I : NOSTR_tag_indexfield {
        try self.init(hexEncodedString:NOSTR_tag_indexfield.NOSTR_tag_indexfield)
    }
	public var NOSTR_tag_indexfield:String {
		return self.hexEncodedString
	}
}

extension nostr.PublicKey:NOSTR_tagged_type {
    public typealias NOSTR_tagged_type_indexfield_TYPE = Self
    public static var NOSTR_tagged_type_namefield:Event.Tag.Name = "p"
}