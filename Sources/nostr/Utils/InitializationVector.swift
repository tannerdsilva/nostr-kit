import RAW

import cnostr

internal struct InitializationVector {
	// 16 byte static buffer
	internal var bytes:(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	/// initialize with random bytes.
	internal init() throws {
		self = try RandomBytes.generate(size:16).asRAW_val({ rawVal in
			return try Self.init(raw:rawVal)
		})
	}

	/// initialize with existing bytes.
	internal init(raw:RAW_val) throws {
		guard raw.mv_size == MemoryLayout<Self>.size else {
			throw Error.invalidInitializationVectorLength
		}
		_ = memcpy(&bytes, raw.mv_data, MemoryLayout<Self>.size)
	}
}

/// RAW_convertible conformance
extension InitializationVector:RAW_encodable {
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to: bytes, { unsafePointer in
			var val = RAW_val(mv_size: MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
			return try valFunc(&val)
		})
	}
}

/// RAW_comparable conformance
extension InitializationVector:RAW_comparable {
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

extension InitializationVector {
	enum Error:Swift.Error {
		case invalidInitializationVectorLength
	}
}