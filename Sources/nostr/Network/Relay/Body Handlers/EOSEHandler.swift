import NIO

extension Relay {
	internal struct EOSEHandler:NOSTR_frame_handler {
		
		internal mutating func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			let sid = try uk.decode(String.self)
		}
	}
}