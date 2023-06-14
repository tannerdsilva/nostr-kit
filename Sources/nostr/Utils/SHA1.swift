import CNIOSHA1

/// SHA1 hashing implementation. 
/// this is needed because we must implement a custom HTTP to websocket upgrader for SwiftNIO, and doing this requires some logic that needs SHA1 hashing.
/// this is a direct port of the C implementation of SHA1 from the SwiftNIO source code.
internal struct SHA1 {
	private var sha1Ctx:SHA1_CTX

	// initialize a new sha1 hashing context
	internal init() {
		self.sha1Ctx = SHA1_CTX()
		c_nio_sha1_init(&self.sha1Ctx)
	}

	/// feed the given string into the hash context as a sequence of UTF-8 bytes
	internal mutating func update(string:String) {
		let isAvailable: ()? = string.utf8.withContiguousStorageIfAvailable {
			self.update($0)
		}
		if isAvailable != nil {
			return
		}
		let buffer = Array(string.utf8)
		buffer.withUnsafeBufferPointer {
			self.update($0)
		}
	}

	/// update the hash context with the given bytes
	internal mutating func update(_ bytes:UnsafeBufferPointer<UInt8>) {
		c_nio_sha1_loop(&self.sha1Ctx, bytes.baseAddress!, bytes.count)
	}

	/// export the hashing.
	/// - Returns: 20 byte hash array
	internal mutating func finish() -> [UInt8] {
		var hashResult: [UInt8] = Array(repeating: 0, count: 20)
		hashResult.withUnsafeMutableBufferPointer {
			$0.baseAddress!.withMemoryRebound(to: Int8.self, capacity: 20) {
				c_nio_sha1_result(&self.sha1Ctx, $0)
			}
		}
		return hashResult
	}
}