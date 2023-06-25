// (c) tanner silva 2023. all rights reserved.

import RAW

public struct Bech32 {

	/// bech32 encode a string
	/// - parameters:
	///		- hrp: human readable part
	/// 	- input: data to encode
	public static func encode(hrp:String, _ input:RAW_val) -> String {
		let bits = eightToFiveBits(input:input)
		let checksum = checksum(hrp:hrp, data:bits)
		return ("\(hrp)" + "1" + String((bits + checksum).map { Self.encCharset[Int($0)] }))
	}

	/// decode a bech32 encoded string
	/// - parameters:
	/// 	- str: string to decode
	/// - throws: ``Bech32.Error``
	public static func decode(_ str:String) throws -> (hrp:String, data:[UInt8]) {
		let strBytes = str.utf8
		guard strBytes.count <= 2024 else {
			throw Bech32.Error.stringLengthExceeded
		}
		var lower:Bool = false
		var upper:Bool = false
		for c in strBytes {
			// printable range
			if c < 33 || c > 126 {
				throw Bech32.Error.nonPrintableCharacter
			}
			// 'a' to 'z'
			if c >= 97 && c <= 122 {
				lower = true
			}
			// 'A' to 'Z'
			if c >= 65 && c <= 90 {
				upper = true
			}
		}
		if lower && upper {
			throw Bech32.Error.invalidCase
		}
		let pos = str.range(of:"1", options:.backwards)?.lowerBound
		guard pos != nil else {
			throw Bech32.Error.noChecksumMarker
		}
		let intPos = str.distance(from:str.startIndex, to:pos!)
		guard intPos >= 1 else {
			throw Bech32.Error.incorrectHrpSize
		}
		guard intPos + 7 <= str.count else {
			throw Bech32.Error.incorrectChecksumSize
		}
		let vSize = str.count - 1 - intPos
		var valuesArr = [UInt8](repeating: 0, count: vSize)
		for i in 0..<vSize {
			let c = strBytes[strBytes.index(strBytes.startIndex, offsetBy:i + intPos + 1)]
			
			let decInt = decCharset[Int(c)]
			if decInt == 255 {
				throw Bech32.Error.invalidCharacter
			}
			valuesArr[i] = decInt
		}

		
		let hrp = String(str.prefix(intPos))
		try valuesArr.asRAW_val { asRaw in
			guard verify(hrp:hrp, checksum:asRaw) else {
				throw Bech32.Error.checksumMismatch
			}
		}
		return try Array(valuesArr[..<(vSize-6)]).asRAW_val { outPtr in
			let converted = try convertBits(outbits:8, input:outPtr, inbits:5, pad:0)
			return (hrp, converted)
		}
	}
}

extension Bech32 {
	fileprivate static let gen:[UInt32] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
	fileprivate static let checksumMarker = "1"
	fileprivate static let decCharset: [UInt8] = [
		255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		15, 255, 10, 17, 21, 20, 26, 30, 7, 5, 255, 255, 255, 255, 255, 255,
		255, 29, 255, 24, 13, 25, 9, 8, 23, 255, 18, 22, 31, 27, 19, 255,
		1, 0, 3, 16, 11, 28, 12, 14, 6, 4, 2, 255, 255, 255, 255, 255,
		255, 29, 255, 24, 13, 25, 9, 8, 23, 255, 18, 22, 31, 27, 19, 255,
		1, 0, 3, 16, 11, 28, 12, 14, 6, 4, 2, 255, 255, 255, 255, 255
	]
	fileprivate static let encCharset:[Character] = [
		"q", "p", "z", "r", "y", "9", "x", "8", "g", "f", "2", "t", "v", "d", "w", "0", "s", "3", "j", "n", "5", "4", "k", "h", "c", "e", "6", "m", "u", "a", "7", "l"
	]

	public enum Error:Swift.Error {
		case nonUTF8String
		case nonPrintableCharacter
		case invalidCase
		case noChecksumMarker
		case incorrectHrpSize
		case incorrectChecksumSize
		case stringLengthExceeded
		case invalidPadding
		case invalidCharacter
		case checksumMismatch
		
		public var errorDescription: String? {
			switch self {
			case .checksumMismatch:
				return "Checksum doesn't match"
			case .incorrectChecksumSize:
				return "Checksum size too low"
			case .incorrectHrpSize:
				return "Human-readable-part is too small or empty"
			case .invalidCase:
				return "String contains mixed case characters"
			case .invalidCharacter:
				return "Invalid character met on decoding"
			case .noChecksumMarker:
				return "Checksum delimiter not found"
			case .nonPrintableCharacter:
				return "Non printable character in input string"
			case .nonUTF8String:
				return "String cannot be decoded by utf8 decoder"
			case .stringLengthExceeded:
				return "Input string is too long"
			case .invalidPadding:
				return "Invalid padding"
			}
		}
	}

	public enum Object {
		public enum Error:Swift.Error {
			case unknownHRP(String)
		}

		case nsec(String)

		case npub(String)

		case note(String)
	}

	internal static func polymod(_ values:RAW_val) -> UInt32 {
		let data = values.mv_data.assumingMemoryBound(to:UInt8.self)
		var chk:UInt32 = 1
		for v in 0..<values.mv_size {
			let top = (chk >> 25)
			chk = (chk & 0x1ffffff) << 5 ^ UInt32(data[v])
			for i:Int in 0..<5 {
				if ((top >> UInt32(i)) & 1) != 0 {
					chk ^= Self.gen[i]
				}
			}
		}
		return chk
	}

	internal static func hrpExpand(_ hrp:String) -> [UInt8] {
		var ret = [UInt8]()
		for c in hrp.utf8 {
			ret.append(c >> 5)
		}
		ret.append(0)
		for c in hrp.utf8 {
			ret.append(c & 31)
		}
		return ret
	}

	internal static func verify(hrp:String, checksum:RAW_val) -> Bool {
		var expandedData = hrpExpand(hrp)
		expandedData += checksum
		return expandedData.asRAW_val({ expandDat in
			return polymod(expandDat) == 1
		})
	}

	internal static func checksum(hrp:String, data:[UInt8]) -> [UInt8] {
		let arr = hrpExpand(hrp) + data + [0, 0, 0, 0, 0, 0]
		return arr.asRAW_val { val in
			let polymod = polymod(val) ^ 1
			var result = [UInt8]()
			for i in 0..<6 {
				let resultVal = ((polymod >> (5 * (5 - UInt32(i)))) & 31)
				result.append(UInt8(resultVal))
			}
			return result
		}
	}

	internal static func convertBits(outbits:Int, input:RAW_val, inbits:Int, pad:Int) throws -> [UInt8] {
		let assumedBound = input.mv_data.assumingMemoryBound(to: UInt8.self)
		let maxv:UInt32 = (1 << outbits) - 1;
		var val:UInt32 = 0
		var bits:Int = 0
		var out = [UInt8]()
		for i in 0..<input.mv_size {
			val = (val << inbits) | UInt32(assumedBound.advanced(by:i).pointee)
			bits += inbits
			while bits >= outbits {
				bits -= outbits
				out.append(UInt8((val >> bits) & maxv))
			}
		}
		if pad != 0 {
			if bits != 0 {
				out.append(UInt8((val << (outbits - bits)) & maxv))
			}
		} else if 0 != ((val << (outbits - bits)) & maxv) || bits >= inbits {
			throw Bech32.Error.invalidPadding
		}
		return out
	}

	internal static func eightToFiveBits(input:RAW_val) -> [UInt8] {
		let assumedBound = input.mv_data.assumingMemoryBound(to: UInt8.self)
		guard input.mv_size > 0 else {
			return []
		}

		var outputSize = (input.mv_size * 8) / 5
		if ((input.mv_size * 8) % 5) != 0 {
			outputSize += 1
		}

		var outputArray = [UInt8]()
		for i in 0..<outputSize {
			let division = (i * 5) / 8
			let remainder = (i * 5) % 8
			var element = assumedBound.advanced(by:division).pointee << remainder
			element >>= 3
			if (remainder > 3) && (i + 1 < outputSize) {
				element = element | (assumedBound.advanced(by:division + 1).pointee >> (8 - remainder + 3))
			}
			outputArray.append(element)
		}
		return outputArray
	}
}