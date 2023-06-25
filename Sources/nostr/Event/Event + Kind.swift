import RAW

// MARK - Kind
extension Event {
	/// represents the various Kinds of events that may be handled
	public enum Kind:Int, Equatable, RAW_convertible, Codable {
		case metadata = 0
		case text_note = 1
		case recommended_relay = 2
		case contacts = 3
		case dm = 4
		case delete = 5
		case boost = 6
		case like = 7
		case channel_create = 8
		case channel_meta = 9
		case chat = 42
		case list = 40000 // (?)
		case zap = 9735
		case zap_request = 9734
		case private_zap = 9733 // I think?
		case list_mute = 10000
		case list_pin = 10001
		case auth_response = 22242
		case list_categorized = 30000
		case list_categorized_bookmarks = 30001
	}
}

extension Event.Kind {		
	public init?(_ value:RAW_val) {
		guard MemoryLayout<Int>.size == value.mv_size else {
			return nil
		}
		guard let asSelf = Self(rawValue:value.mv_data.bindMemory(to:Int.self, capacity:1).pointee) else {
			return nil
		}
		self = asSelf
	}
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.rawValue) { rawVal in
			var val = RAW_val(mv_size:MemoryLayout<Int>.size, mv_data:UnsafeMutableRawPointer(mutating: rawVal))
			return try valFunc(&val)
		}
	}
}