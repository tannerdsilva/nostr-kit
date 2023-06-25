import XCTest
@testable import nostr

final class nostr_keyTests: XCTestCase {
	internal static let keyPair = try! KeyPair(seckey:SecretKey(nsec:"nsec1s23j6z0x4w2y35c5zkf6le539sdmkmw4r7mm9jj22gnltrllqxzqjnh2wm"))
	func testKeyParsing() throws {
		let pubkey = Self.keyPair.pubkey
		XCTAssertEqual(pubkey.description, "035ff097e48189cd26e98d65991c7a3cf95b4c87a6b2f636a69c1738ff5dd229")
	}
}