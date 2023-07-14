import XCTest
@testable import nostr
import Foundation

final class nostr_kitTests: XCTestCase {
	func testTannerNIP05() async throws {
		let tannersNIP:NIP05 = NIP05(local:"t", domain:"tannersilva.com")
		// let encoded = try JSONEncoder().encode(tannersNIP)
		try await tannersNIP.verify()
		// fatalError(String(bytes:encoded, encoding:.utf8) ?? "could not encode")
	}
}
