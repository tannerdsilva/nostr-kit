import XCTest
@testable import nostr

class EventTests: XCTestCase {
	internal static let keyPair = try! KeyPair(seckey:SecretKey(nsec:"nsec1s23j6z0x4w2y35c5zkf6le539sdmkmw4r7mm9jj22gnltrllqxzqjnh2wm"))

	func testGenerateUID() throws {
		var usEvent = Event.Unsigned(kind:.text_note)
		usEvent.date = Date(unixInterval: 1700)
		usEvent.content = "Test content"
		let event = try usEvent.sign(type:Event.Signed.self, as:EventTests.keyPair)
		let uidString = event.uid.hexEncodedString()
		XCTAssertEqual(uidString, "14550304c8f98a7dfd9918f06fb8387f471359e7117861f0cfc4868ee7212368")
	}
	
	func testEventSignatureValidation() throws {

		var unsignedEvent = Event.Unsigned(kind:.text_note)
		unsignedEvent.content = "test content"

		// Sign the event
		let event = try unsignedEvent.sign(type:nostr.Event.Signed.self, as:EventTests.keyPair)

		// Validate the event's signature
		XCTAssertTrue(event.isSignatureValid(), "Event signature should be valid")
	}
}
