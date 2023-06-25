// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import RAW

/// returns a ``time_t`` struct representing the reference date for this Date type.
/// **NOTE**: the reference date is 00:00:00 UTC on 1 January 2001.
fileprivate func systemReferenceDate() -> time_t {
	var timeStruct = tm()
	memset(&timeStruct, 0, MemoryLayout<tm>.size)
	timeStruct.tm_mday = 1
	timeStruct.tm_mon = 0
	timeStruct.tm_year = 101
	return mktime(&timeStruct)
}
internal let refDate = systemReferenceDate()

/// returns a ``time_t`` struct representing the reference date for this Date type.
/// **NOTE**: the reference date is 00:00:00 UTC on 1 January 1970.
fileprivate func encodingReferenceDate() -> time_t {
	var timeStruct = tm()
	memset(&timeStruct, 0, MemoryLayout<tm>.size)
	timeStruct.tm_mday = 1
	timeStruct.tm_mon = 0
	timeStruct.tm_year = 70
	return mktime(&timeStruct)
}
internal let encDate = encodingReferenceDate()

@frozen 
public struct Date {
	/// the primitive value of this instance.
	/// represents the seconds elapsed since 00:00:00 UTC on 1 January 2001
	private let rawVal:Double

	/// initialize with the current time
	public init() {
		var makeTime = time_t()
		time(&makeTime)
		self.rawVal = difftime(makeTime, refDate)
	}

	public init(unixInterval:Double) {
		rawVal = unixInterval + 978307200
	}

	/// basic initializer based on the primitive
	public init(referenceDate:Double) {
		self.rawVal = referenceDate
	}

	/// returns the difference in time between the called instance and passed date
	public func timeIntervalSince(_ other:Self) -> Double {
		return self.rawVal - other.rawVal
	}

	/// returns a new value that is the sum of the current value and the passed interval
	public func addingTimeInterval(_ interval:Double) -> Self {
		return Self(referenceDate:self.rawVal + interval)
	}

	/// returns the time interval since the reference date
	public func timeIntervalSinceReferenceDate() -> Double {
		return self.rawVal
	}

	/// returns the time interval since unix epoch
	public func timeIntervalSinceUnixDate() -> Double {
		return self.rawVal - 978307200
	}
}

extension Date:Codable {
	public init(from decoder:Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.init(unixInterval:Double(try container.decode(UInt64.self)))
	}
	public func encode(to encoder:Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(UInt64(self.timeIntervalSinceUnixDate()))
	}
}

extension Date:RAW_convertible {
	/// initialize from database
	public init?(_ value:RAW_val) {
		guard MemoryLayout<Self>.size == value.mv_size else {
			return nil
		}
		self = value.mv_data.bindMemory(to:Self.self, capacity:1).pointee
	}

	/// encode into database
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self, { unsafePointer in
			var val = RAW_val(mv_size:MemoryLayout<Self>.size, mv_data:UnsafeMutableRawPointer(mutating:unsafePointer))
			return try valFunc(&val)
		})
	}
}

extension Date:RAW_comparable {
	/// custom LMDB comparison function for the encoding scheme of this type
	public static let rawCompareFunction:@convention(c) (UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 = { a, b in
		let aTI = a!.pointee.mv_data!.assumingMemoryBound(to: Self.self).pointee
		let bTI = b!.pointee.mv_data!.assumingMemoryBound(to: Self.self).pointee
		if aTI.rawVal < bTI.rawVal {
			return -1
		} else if aTI.rawVal > bTI.rawVal {
			return 1
		} else {
			return 0
		}
	}
}

extension Date:Hashable, Equatable, Comparable {
	/// hashable conformance
	public func hash(into hasher:inout Hasher) {
		hasher.combine(rawVal)
	}

	/// comparable conformance
	static public func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			rhs.asRAW_val({ rhsVal in
				Self.rawCompareFunction(&lhsVal, &rhsVal) < 0
			})
		})
	}

	/// equatable conformance
	static public func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.rawVal == rhs.rawVal
	}
}