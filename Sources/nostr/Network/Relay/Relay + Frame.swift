import NIO

extension Relay {
	internal struct Frame {
		internal let name:String
		internal let contents:[any Codable]
	}
}

extension Relay.Frame:Encodable {
	public func encode(to encoder:Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(self.name)
		for content in self.contents {
			try container.encode(content)
		}
	}
}