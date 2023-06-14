import XCTest
@testable import nostr
import Foundation

final class DateTests:XCTestCase {
	func testInitMatchesFoundationDate() {
		var Cnow = time(nil);
		let loc = localtime(&Cnow).pointee
		var offset = Double(loc.tm_gmtoff)
		if loc.tm_isdst > 0 {
			offset -= 3600
		}
		let myDate = nostr.Date()
		
		// Create a new Foundation.Date from the components, which is timezone-independent (UTC)
		let foundationDate = Foundation.Date()
		
		let myDateReferenceInterval = myDate.timeIntervalSinceReferenceDate()
		let foundationDateReferenceInterval = foundationDate.timeIntervalSinceReferenceDate

		// Assert they are approximately equal, allowing for up to 1 second difference due to init time difference
		XCTAssertEqual(myDateReferenceInterval, foundationDateReferenceInterval + offset, accuracy: 1.0)
	}
}