import NIO

/// a protocol expression that allows programming objects to implement a custom frame body parser and handler.
public protocol NOSTR_frame_handler {
	/// the body parser and handler
	func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:NIOCore.ChannelHandlerContext) throws
}

/// a protocol expression that allows programming objects to express their type as representing a single frame instance
/// - this protocol gets an automatic implementation of ``NOSTR_frame_encodable``
public protocol NOSTR_frame:NOSTR_frame_encodable {
	/// the identifying name of the frame (identifies the data that will follow)
	/// - examples of frames:
	/// 	- `OK`
	/// 	- `EVENT`
	///		- `AUTH`
	///		- `EOSE`
	var NOSTR_frame_name:String { get }

	/// the contents of the frame following the name.
	var NOSTR_frame_contents:[any Codable] { get }
}

extension NOSTR_frame {
	// default frame encode implementation
	public func NOSTR_frame_encode() -> Relay.EncodingFrame {
		return Relay.EncodingFrame(name:self.NOSTR_frame_name, contents:self.NOSTR_frame_contents)
	}
}

/// a protocol expression that allows programming objects to encode themselves 
public protocol NOSTR_frame_encodable {
	/// encodes this instance into its corresponding frame representation
	func NOSTR_frame_encode() -> Relay.EncodingFrame
}