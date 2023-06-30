import XCTest
@testable import nostr
import Foundation

final class DateTests:XCTestCase {
	func testInitMatchesFoundationDate() {
		let myDate = nostr.Date()
		
		// Create a new Foundation.Date from the components, which is timezone-independent (UTC)
		let foundationDate = Foundation.Date()
		
		let myDateReferenceInterval = myDate.timeIntervalSinceReferenceDate()
		let foundationDateReferenceInterval = foundationDate.timeIntervalSinceReferenceDate

		// Assert they are approximately equal, allowing for up to 1 second difference due to init time difference
		XCTAssertEqual(myDateReferenceInterval, foundationDateReferenceInterval, accuracy: 1.0)
	}
}