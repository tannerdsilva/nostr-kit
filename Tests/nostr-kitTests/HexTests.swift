import XCTest
@testable import nostr

final class HexTests:XCTestCase {
	func testEncodeLowercase() {
		let og:[UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
		og.asRAW_val { origData in
			let encodedString = Hex.encode(origData, lowercaseOutput: true)
			XCTAssertEqual(encodedString, "0123456789abcdef")
		}
	}

	func testEncodeUppercase() {
		let og:[UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
		og.asRAW_val { origData in
			let encodedString = Hex.encode(origData, lowercaseOutput: false)
			XCTAssertEqual(encodedString, "0123456789ABCDEF")
		}
	}
	
	func testDecode() throws {
		let testString = "0123456789abcdef"
		let decodedData = try Hex.decode(testString)
		let expectedData: [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
		XCTAssertEqual(decodedData, expectedData)
	}
	
	func testEncodeDecodeLowercase() throws  {
		let og: [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
		try og.asRAW_val { origData in
			let encodedString = Hex.encode(origData, lowercaseOutput: false)
			let decodedData = try Hex.decode(encodedString)
			XCTAssertEqual(decodedData, og)
		}
	}

	func testEncodeDecodeUppercase() throws {
		let og: [UInt8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
		try og.asRAW_val { origData in
			let encodedString = Hex.encode(origData, lowercaseOutput: false)
			let decodedData = try Hex.decode(encodedString)
			XCTAssertEqual(decodedData, og)
		}
	}
}
