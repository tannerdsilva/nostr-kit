import NIO

/// used to allow a programming object to express a name that correlates with a frame body handler.
public protocol NOSTR_frame_types:ExpressibleByDictionaryLiteral {
	associatedtype DictionaryLiteralType = [String:any NOSTR_frame_handler.Type]

	/// the body handler instances that can be used to handle the body of a frame.
	static var NOSTR_frame_types:[String:any NOSTR_frame_handler.Type] { get }
}

/// a protocol expression that allows programming objects to implement a custom frame body parser and handler.
public protocol NOSTR_frame_handler {
	/// the type that the body parser is decoding into.
	associatedtype NOSTR_frame_TYPE:NOSTR_frame

	/// the body parser.
	static func NOSTR_frame_handler_parse(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_frame_TYPE
	
	/// instance handler for the decoded body after it has been parsed by the static parse function.
	mutating func NOSTR_frame_handle(_ decoded:NOSTR_frame_TYPE, context:NIOCore.ChannelHandlerContext) throws
}

/// a protocol expression that allows programming objects to express a single frame instance
public protocol NOSTR_frame {
	/// the identifying name of the frame (identifies the data that will follow)
	var NOSTR_frame_name:String { get }

	/// the contents of the frame following the name.
	var NOSTR_frame_contents:[any Codable] { get }
}