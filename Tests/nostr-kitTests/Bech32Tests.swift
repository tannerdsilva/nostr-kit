import XCTest
@testable import nostr

final class Bech32Tests:XCTestCase {
	func testEightToFiveBits() throws { 
		let inputString = try Hex.decode("2ef0fccfd5a55e36bc8be3a525c1ce97f20eabaa94e69d82febfd641d9480c35")
		inputString.asRAW_val { rv in
			let expectedOutput: [UInt8] = [5, 27, 24, 15, 25, 19, 30, 21, 20, 21, 15, 3, 13, 15, 4, 11, 28, 14, 18, 18, 11, 16, 14, 14, 18, 31, 25, 0, 29, 10, 29, 10, 18, 19, 19, 9, 27, 0, 23, 30, 23, 31, 11, 4, 3, 22, 10, 8, 1, 16, 26, 16]
			let output = Bech32.eightToFiveBits(input: rv)
			XCTAssertEqual(output, expectedOutput, "Expected output doesn't match the actual output.")
		}
	}

	func testChecksum() {
		let hrp = "npub"
		let data: [UInt8] = [5, 27, 24, 15, 25, 19, 30, 21, 20, 21, 15, 3, 13, 15, 4, 11, 28, 14, 18, 18, 11, 16, 14, 14, 18, 31, 25, 0, 29, 10, 29, 10, 18, 19, 19, 9, 27, 0, 23, 30, 23, 31, 11, 4, 3, 22, 10, 8, 1, 16, 26, 16]
		let expectedOutput: [UInt8] = [22, 1, 2, 7, 30, 20]
		let output = Bech32.checksum(hrp: hrp, data: data)
		XCTAssertEqual(output, expectedOutput, "Expected output doesn't match the actual output.")
	}

	func testConvertBits() throws {
        let inputBytes: [UInt8] = [
            5, 27, 24, 15, 25, 19, 30, 21, 20, 21, 15, 3, 13, 15, 4, 11, 28, 14, 18, 18,
            11, 16, 14, 14, 18, 31, 25, 0, 29, 10, 29, 10, 18, 19, 19, 9, 27, 0, 23, 30,
            23, 31, 11, 4, 3, 22, 10, 8, 1, 16, 26, 16
        ]
		let expectedOutput: [UInt8] = [
			46, 240, 252, 207, 213, 165, 94, 54, 188, 139, 227, 165, 37, 193, 206, 151,
			242, 14, 171, 170, 148, 230, 157, 130, 254, 191, 214, 65, 217, 72, 12, 53
		]
        let data = try inputBytes.asRAW_val { inputData in
			return try Bech32.convertBits(outbits: 8, input: inputData, inbits: 5, pad: 0)
		}
		XCTAssertEqual(data, expectedOutput, "Expected output doesn't match the actual output.")
    }

	func testBech32Encode() throws {
		let inputString = try Hex.decode("2ef0fccfd5a55e36bc8be3a525c1ce97f20eabaa94e69d82febfd641d9480c35")
		inputString.asRAW_val { input in
			let expectedOutput = "npub19mc0en74540rd0ytuwjjtswwjleqa2a2jnnfmqh7hltyrk2gps6skpz875"
			let output = Bech32.encode(hrp: "npub", input)
			XCTAssertEqual(output, expectedOutput, "Expected output doesn't match the actual output.")
		}
	}

	func testBech32Decode() throws {
		let inputString = "npub19mc0en74540rd0ytuwjjtswwjleqa2a2jnnfmqh7hltyrk2gps6skpz875"
		let bytes = try Bech32.decode(inputString)
		let expectedResult: [UInt8] = [46, 240, 252, 207, 213, 165, 94, 54, 188, 139, 227, 165, 37, 193, 206, 151, 242, 14, 171, 170, 148, 230, 157, 130, 254, 191, 214, 65, 217, 72, 12, 53]
		XCTAssertEqual(bytes.data, expectedResult, "Expected output doesn't match the actual output.")
	}
}