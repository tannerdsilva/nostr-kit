import NIO

extension Relay {
	internal struct NOTICEHandler:NOSTR_frame_handler {
	    func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context: NIOCore.ChannelHandlerContext) throws {
	        
	    }
	}
}