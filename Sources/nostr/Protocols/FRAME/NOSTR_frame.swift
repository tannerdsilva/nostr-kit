import NIO

/// a protocol expression that allows programming objects to implement a custom frame body parser and handler.
public protocol NOSTR_frame_handler {
	/// the body parser and handler
	mutating func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:NIOCore.ChannelHandlerContext) throws
}

/// a protocol expression that allows programming objects to express a single frame instance
public protocol NOSTR_frame {
	/// the identifying name of the frame (identifies the data that will follow)
	var NOSTR_frame_name:String { get }

	/// the contents of the frame following the name.
	var NOSTR_frame_contents:[any Codable] { get }
}