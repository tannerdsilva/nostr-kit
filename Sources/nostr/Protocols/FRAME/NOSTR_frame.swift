import NIO

/// used to allow a programming object to express a name that correlates with a frame body handler.
public protocol NOSTR_frame_nametypes:ExpressibleByArrayLiteral {
	/// use any NOSTR_frame_body.Type as the value for the name.
	associatedtype ArrayLiteralElement = any NOSTR_frame_body.Type
	
	/// the body handler instances that can be used to handle the body of a frame.
	static var NOSTR_frame_nametypes:[String:any NOSTR_frame_body.Type] { get }
}

/// a protocol expression that allows programming objects to implement a custom frame body parser and handler.
public protocol NOSTR_frame_body {
	/// the type that the body parser is decoding into.
	associatedtype NOSTR_frame_body_decoded_TYPE

	/// the body parser.
	static func parseBody(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_frame_body_decoded_TYPE
	
	/// the handler for the body parser instance.
	mutating func handleDecodedBody(_ decoded:NOSTR_frame_body_decoded_TYPE, context: NIOCore.ChannelHandlerContext) throws
}

