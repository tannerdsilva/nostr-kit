import RAW

public struct Hex {
	/// thrown when an invalid character is encountered during decoding
	public struct InvalidInput:Swift.Error {
		/// the character that caused the error
		public let character:Character
		/// the index of the character in the input string
		public let index:Int
	}

	/// hex encode a data buffer.
	/// - parameter rawDat: the data buffer to encode
	/// - parameter lowercaseOutput: whether to output the hex encoded string in lowercase or not
	/// - returns: a string containing the hex encoded data
	/// - **NOTE:** this function does not check if the data is valid. if an invalid data buffer is passed, the result is undefined.
	public static func encode(_ rawDat:RAW_val, lowercaseOutput:Bool = false) -> String {
		var str = ""
		let data = UnsafeRawBufferPointer(start:rawDat.mv_data, count:rawDat.mv_size)
		if (lowercaseOutput) {
			// loop with lowercase append
			for i in 0..<rawDat.mv_size {
				let c1 = hexchar(data[i] >> 4)
				let c2 = hexchar(data[i] & 0xF)
				str.append(Character(Unicode.Scalar(c1)).lowercased())
				str.append(Character(Unicode.Scalar(c2)).lowercased())
			}
		} else {
			// loop with uppercase append
			for i in 0..<rawDat.mv_size {
				let c1 = hexchar(data[i] >> 4)
				let c2 = hexchar(data[i] & 0xF)
				str.append(Character(Unicode.Scalar(c1)).uppercased())
				str.append(Character(Unicode.Scalar(c2)).uppercased())
			}
		}
		return str
	}

	/// decode a hex encoded string.
	/// - parameter str: the string to decode
	/// - returns: a data buffer containing the decoded data
	public static func decode(_ str:String) throws -> [UInt8] {
		var result: [UInt8] = []
		let characters = Array(str.utf8)
		let length = characters.count
		var i = 0
		while i < length {
			let c1 = char_to_hex(characters[i])
			guard c1 != 255 else {
				throw InvalidInput(character:Character(Unicode.Scalar(characters[i])), index:i)
			}
			let c2 = char_to_hex(characters[i + 1])
			guard c2 != 255 else {
				throw InvalidInput(character:Character(Unicode.Scalar(characters[i + 1])), index:i + 1)
			}
			let byte = (c1 << 4) | c2
			result.append(byte)
			i += 2
		}
		return result
	}
}

/// returns a value to a given hex character
/// - parameter val: the hex character to convert
/// - returns: the value of the hex character
/// - **NOTE:** this function does not check if the character is a valid hex character. if an invalid character is passed, the result is undefined.
fileprivate func hexchar(_ val: UInt8) -> UInt8 {
	if val < 10 {
		return 48 + val
	} else if val < 16 {
		return 65 + val - 10  // 'A' to 'F' for hexadecimal
	} else {
		fatalError("invalid input for hex conversion: \(val)")
	}
}


/// returns the hex character value of a given byte
/// - parameter c: the byte to convert
/// - returns: the hex character value of the byte or 255 if the byte is not a valid hex character
fileprivate func char_to_hex(_ c:UInt8) -> UInt8 {
	if c >= 0x30 && c <= 0x39 {
		// 0 - 9
		return c - 0x30
	} else if c >= 0x61 && c <= 0x66 {
		// a - f
		return c - 0x61 + 0xA
	} else if c >= 0x41 && c <= 0x46 {
		// A - F
		return c - 0x41 + 0xA
	} else {
		return 255
	}
}