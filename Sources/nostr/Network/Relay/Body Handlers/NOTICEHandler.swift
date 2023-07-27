import NIO

extension Relay {
	internal struct NOTICEHandler:NOSTR_frame_handler {
	    mutating func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context: NIOCore.ChannelHandlerContext) throws {
	        
	    }
	}
}