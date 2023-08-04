import NIO

extension Relay {
	/// a container struct that is used to package and serialize contents into a relay frame.
	public struct EncodingFrame {
		/// the identifying name of the frame (identifies the data that will follow)
		internal let name:String

		/// the contents of the frame following the name.
		internal let contents:[any Codable]
	}
}

extension Relay.EncodingFrame:Encodable {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(self.name)
		for content in self.contents {
			try container.encode(content)
		}
	}
}

extension Relay.EncodingFrame:NOSTR_frame {
	public var NOSTR_frame_name:String {
		return self.name
	}

	public var NOSTR_frame_contents:[any Codable] {
		return self.contents
	}
}