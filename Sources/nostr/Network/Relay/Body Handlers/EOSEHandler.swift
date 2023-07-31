import NIO

extension Relay {
	internal class EOSEHandler:NOSTR_frame_handler {
		
		internal func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			let sid = try uk.decode(String.self)
		}
	}
}