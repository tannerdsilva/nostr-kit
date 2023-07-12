// (c) tanner silva 2023. all rights reserved.

import RAW
import cnostr

extension Event.Signed {
	/// defines the 64 byte signature of a nostr event.
	@frozen public struct Signature {
		// 64 byte static buffer
		internal var bytes:(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	}
}

/// the event UID is codable by way of its hex encoded string value.
extension Event.Signed.Signature:Codable {
	public init(from decoder:Swift.Decoder) throws {
		let container = try decoder.singleValueContainer()
		let hexEncodedString = try container.decode(String.self)
		try self.init(hexEncodedString:hexEncodedString)
	}
	public func encode(to encoder:Swift.Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.hexEncodedString())
	}
}

/// the event signature is RAW convertible
extension Event.Signed.Signature:RAW_convertible {
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
extension Event.Signed.Signature:RAW_comparable {
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

/// implements the HEX_convertible protocol
extension Event.Signed.Signature:HEX_convertible {
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

extension Event.Signed.Signature {
	public enum Error: Swift.Error {
		/// thrown when decoding using ``Decodable` protocol. specifically thrown when a string value is successfully extraced froma single value container, but the string could not be handled.
		case encodedStringInvalid
	}
}