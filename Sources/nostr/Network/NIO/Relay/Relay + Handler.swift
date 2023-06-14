import NIOCore

extension Relay {
	internal final class Handler:ChannelDuplexHandler {
		typealias InboundIn = ByteBuffer
		typealias OutboundIn = Message
		typealias InboundOut = Message
		typealias OutboundOut = ByteBuffer
	}
}