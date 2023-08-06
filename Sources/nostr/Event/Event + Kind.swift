// (c) tanner silva 2023. all rights reserved.

import RAW

// MARK - Kind
extension Event {

	/// represents the various Kinds of events that may be handled
	public enum Kind:UInt64, Equatable, Comparable, Codable, Hashable {
		case metadata = 0
		case text_note = 1
		case recommended_relay = 2
		case contacts = 3
		case dm = 4
		case delete = 5
		case boost = 6
		case like = 7
		case chat = 42
		case list = 40000
		case list_mute = 10000
		case list_pin = 10001
		case auth_response = 22242
		case list_categorized = 30000
		case list_categorized_bookmarks = 30001
	}
}

extension Event.Kind {
	public static func < (lhs:Event.Kind, rhs:Event.Kind) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}
}