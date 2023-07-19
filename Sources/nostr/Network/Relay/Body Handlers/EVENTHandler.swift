
extension Relay {
	internal struct EVENTHandler:NOSTR_frame_handler {

		struct NOSTR_frame_TYPE:NOSTR_frame {
			let sid:String
			let event:NOSTR

			var NOSTR_frame_name:String {
				return "EVENT"
			}
			var NOSTR_frame_contents:[any Codable] {
				return [event]
			}
		}
	}
}