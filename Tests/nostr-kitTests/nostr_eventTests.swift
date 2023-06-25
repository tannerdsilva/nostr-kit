import XCTest
@testable import nostr

class EventTests: XCTestCase {
	internal static let keyPair = try! KeyPair(seckey:SecretKey(nsec:"nsec1s23j6z0x4w2y35c5zkf6le539sdmkmw4r7mm9jj22gnltrllqxzqjnh2wm"))

	func testGenerateUID() throws {
		var event = Event()
		event.content = "Test content"
		event.tags = []
		event.pubkey = Self.keyPair.pubkey
		event.created = Date(unixInterval:1700)
		event.kind = nostr.Event.Kind.text_note
		
		try event.computeUID()
		let uidString = event.uid.description
		XCTAssertEqual(uidString, "14550304c8f98a7dfd9918f06fb8387f471359e7117861f0cfc4868ee7212368")

	}
	func testEventSignatureValidation() throws {
		// Create a test event
		var event = Event()
		event.content = "Test content"
		event.tags = []
		event.pubkey = Self.keyPair.pubkey
		event.created = Date()
		event.kind = nostr.Event.Kind.text_note
		
		try event.computeUID()

		// Sign the event
		try event.sign(Self.keyPair.seckey)

		// Validate the event's signature
		XCTAssertTrue(event.isValid(), "Event signature should be valid")
	}
}
