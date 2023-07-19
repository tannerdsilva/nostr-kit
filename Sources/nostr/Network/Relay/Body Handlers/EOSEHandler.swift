import NIO

extension Relay {
	internal struct EOSEHandler:NOSTR_frame_handler {
		internal static func NOSTR_frame_handler_parse(_ uk: inout UnkeyedDecodingContainer) throws -> NOSTR_frame_TYPE {
			return try .init(sid: uk.decode(String.self))
		}

		internal mutating func NOSTR_frame_handle(_ decoded:NOSTR_frame_TYPE, context:ChannelHandlerContext) throws {
			
		}

		internal struct NOSTR_frame_TYPE:NOSTR_frame {
			let sid:String

			var NOSTR_frame_name:String {
				return "EOSE"
			}
			var NOSTR_frame_contents:[any Codable] {
				return [sid]
			}
		}
	}
}