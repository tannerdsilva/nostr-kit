// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

import RAW

extension Event {
	/// a unique identifier for an event. represents the raw 32 byte value of the event UID.
	public struct UID {
		internal var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	}
}

/// RAW_convertible conformance
extension Event.UID:RAW_convertible {
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
extension Event.UID:RAW_comparable {
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
extension Event.UID:LosslessStringConvertible {
	public init?(_ description: String) {
		do {
			let decoded = try Hex.decode(description)
			guard let makeSelf = decoded.asRAW_val({ bytesVal in
				return Self.init(bytesVal)
			}) else {
				return nil
			}
			self = makeSelf
		} catch {
			return nil
		}
	}
	public var description: String {
		self.asRAW_val { rval in
			return Hex.encode(rval, lowercaseOutput:true)
		}
	}
}

/// Codable conformance
extension Event.UID:Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let description = try container.decode(String.self)
		guard let makeSelf = Self.init(description) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UID")
		}
		self = makeSelf
	}
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}
}

/// Hashable, Equatable, Comparable conformance
extension Event.UID:Equatable, Hashable, Comparable {
	public static func == (lhs: nostr.Event.UID, rhs: nostr.Event.UID) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) == 0
			})
		})
	}
	
	public static func < (lhs: nostr.Event.UID, rhs: nostr.Event.UID) -> Bool {
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