// (c) tanner silva 2023. all rights reserved.

import Crypto
import RAW

extension SHA256 {
	internal static func hash<R>(_ val:R) -> [UInt8] where R:RAW_encodable {
		return val.asRAW_val { valVal in
			var hasher = SHA256()
			let asBuff = UnsafeRawBufferPointer(start:valVal.mv_data, count:valVal.mv_size)
			hasher.update(bufferPointer:asBuff)
			return hasher.finalize().withUnsafeBytes { bytesBuff in
				let asRAW = RAW_val(mv_size:bytesBuff.count, mv_data:UnsafeMutableRawPointer(mutating: bytesBuff.baseAddress!))
				return Array(asRAW)
			}
		}
	}

	internal static func hash(_ val:RAW_val) -> [UInt8] {
		var hasher = SHA256()
		let asBuff = UnsafeRawBufferPointer(start:val.mv_data, count:val.mv_size)
		hasher.update(bufferPointer:asBuff)
		return hasher.finalize().withUnsafeBytes { bytesBuff in
			let asRAW = RAW_val(mv_size:bytesBuff.count, mv_data:UnsafeMutableRawPointer(mutating: bytesBuff.baseAddress!))
			return Array(asRAW)
		}
	}
}