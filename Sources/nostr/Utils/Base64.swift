import cnostr
import RAW

extension String {
	static func base64Encoded(_ rawVal:RAW_val) -> String {
		let newBytes = malloc(base64_encoded_length(rawVal.mv_size))
		defer {
			free(newBytes)
		}
		base64_encode(newBytes, base64_encoded_length(rawVal.mv_size), rawVal.mv_data, rawVal.mv_size)
		return String(cString:newBytes!.assumingMemoryBound(to:Int8.self))
	}
	static func base64Encoded(bytes:[UInt8]) -> String {
		let enclen = base64_encoded_length(bytes.count) + 1
		let newBytes = malloc(enclen)
		defer {
			free(newBytes)
		}
		let encodedLength = bytes.asRAW_val({ rv in
			base64_encode(newBytes, enclen, rv.mv_data, bytes.count)
		})
		assert(encodedLength >= 0)
		return String(cString:newBytes!.assumingMemoryBound(to:Int8.self))
	}
	func base64DecodedBytes() -> [UInt8] {
		let newBytes = malloc(base64_decoded_length(self.count))
		defer {
			free(newBytes)
		}
		let decodeResult = base64_decode(newBytes, base64_decoded_length(self.count), self, self.count)
		guard decodeResult >= 0 else {
			fatalError("could not decode base64 string")
		}
		return Array(UnsafeBufferPointer(start:newBytes!.assumingMemoryBound(to:UInt8.self), count:decodeResult))
	}
}