// (c) tanner silva 2023. all rights reserved.

import RAW

extension UnsafeRawBufferPointer:RAW_encodable {
    public func asRAW_val<R>(_ valFunc: (inout RAW.RAW_val) throws -> R) rethrows -> R {
        var raw = RAW_val(mv_size:self.count, mv_data:UnsafeMutableRawPointer(mutating:self.baseAddress))
		return try valFunc(&raw)
    }
}