// (c) tanner silva 2023. all rights reserved.

import cnostr
import RAW

extension Event.Signed {
	/// a unique identifier for an event. represents the raw 32 byte value of the event UID.
	@frozen public struct UID {
		internal var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	}
}

/// RAW_convertible conformance
extension Event.Signed.UID:RAW_convertible {
	public init?(_ value:RAW_val) {
		guard value.mv_size == MemoryLayout<Self>.size else {
			return nil
		}
		_ = memcpy(&bytes, value.mv_data, MemoryLayout<Self>.size)
	}
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to: bytes, { unsafePointer in
			var val = RAW_val(mv_size: MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
			return try valFunc(&val)
		})
	}
}

/// RAW_comparable conformance
extension Event.Signed.UID:RAW_comparable {
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

extension Event.Signed.UID:HEX_convertible {
	public init(hexEncodedString: String) throws {
		let decoded = try Hex.decode(hexEncodedString)
		guard decoded.count == MemoryLayout<Self>.size else {
			throw Error.encodedStringInvalid
		}
		let makeSelf = decoded.asRAW_val({ bytesVal in
			return Self.init(bytesVal)!
		})
		self = makeSelf
	}
	public func hexEncodedString() -> String {
		self.asRAW_val { rval in
			return Hex.encode(rval, lowercaseOutput:true)
		}
	}
}

/// LosslessStringConvertible conformance
extension Event.Signed.UID:CustomStringConvertible {
	public var description: String {
		return self.hexEncodedString()
	}
}

/// Codable conformance
extension Event.Signed.UID:Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let description = try container.decode(String.self)
		let makeSelf = try Self.init(hexEncodedString:description)
		self = makeSelf
	}
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.hexEncodedString())
	}
}

/// Hashable, Equatable, Comparable conformance
extension Event.Signed.UID:Equatable, Hashable, Comparable {
	public static func == (lhs: nostr.Event.Signed.UID, rhs: nostr.Event.Signed.UID) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) == 0
			})
		})
	}
	
	public static func < (lhs: nostr.Event.Signed.UID, rhs: nostr.Event.Signed.UID) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) < 0
			})
		})
	}

	public func hash(into hasher:inout Hasher) {
		asRAW_val({ hashVal in
			hasher.combine(hashVal)
		})
	}
}

extension Event.Signed.UID {
	public enum Error: Swift.Error {
		/// thrown when decoding using ``Decodable` protocol. specifically thrown when a string value is successfully extraced froma single value container, but the string could not be handled.
		case encodedStringInvalid
	}
}