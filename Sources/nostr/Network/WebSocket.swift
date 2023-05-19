import NIOCore
import NIOWebSocket
import NIOHTTP1

public struct WebSocket {}

public extension WebSocket {
	enum Data:Equatable, Sendable {
		case text(String)
		case binary(ByteBuffer)
		case ping
		case pong
	}

	internal typealias URL = Relay.URL
	internal class Handler:ChannelDuplexHandler {
		/// The handler for pings and pongs as they are handled in the channel. The first parameter is the frame that was received, the second is whether or not it was a pong.
		public typealias PingPongHandler = (WebSocketFrame, Bool /*isPong?*/ ) -> Void
		public typealias InboundIn = WebSocketFrame
		public typealias InboundOut = Data
		public typealias OutboundIn = Data
		public typealias OutboundOut = WebSocketFrame
		
		let pingPongHandler:PingPongHandler
		var webSocketFrameSequence:FrameSequence? = nil
		let url:Relay.URL

		public init(url:URL, _ handler:@escaping(PingPongHandler)) {
			self.pingPongHandler = handler
			self.url = url
		}

		public func channelRead(context:ChannelHandlerContext, data:NIOAny) {
			let frame: InboundIn = self.unwrapInboundIn(data)
			switch frame.opcode {
				case .pong:
					pingPongHandler(frame, true)
				case .ping:
					pingPongHandler(frame, false)
				case .text:
				if var frameSeq = self.webSocketFrameSequence {
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				} else {
					var frameSeq = FrameSequence(type: .text)
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				}
			case .binary:
				if var frameSeq = self.webSocketFrameSequence {
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				} else {
					var frameSeq = FrameSequence(type: .binary)
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				}
			case .continuation:
				if var frameSeq = self.webSocketFrameSequence {
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				} else {
					context.channel.close(mode:.all, promise: nil)
				}
			case .connectionClose:
				context.channel.close(mode:.all, promise: nil)

			default:
				break
			}

			if let frameSeq = self.webSocketFrameSequence, frame.fin {
				context.fireChannelRead(self.wrapInboundOut(frameSeq.combinedResult))
				self.webSocketFrameSequence = nil
			}
		}

		public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
			let message: OutboundIn = self.unwrapOutboundIn(data)
			let frame: WebSocketFrame
			switch message {
			case .text(let text):
				var buffer = context.channel.allocator.buffer(capacity: text.utf8.count)
				buffer.writeString(text)
				frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
			case .binary(let binary):
				frame = WebSocketFrame(fin: true, opcode: .binary, data: binary)
			case .ping:
				frame = WebSocketFrame(fin: true, opcode: .ping, data: ByteBuffer())
			case .pong:
				frame = WebSocketFrame(fin: true, opcode: .pong, data: ByteBuffer())
			}
			context.write(self.wrapOutboundOut(frame), promise: promise)
		}
	}
}

extension WebSocket {
	/// Default HTTP error. Provides an HTTP status and a message is so desired
	public struct HTTPError:Error, Sendable {
		/// status code for the error
		public let status: HTTPResponseStatus
		/// any addiitional headers required
		public let headers: HTTPHeaders
		/// error payload, assumed to be a string
		public let body: String?

		/// Initialize HTTPError
		/// - Parameters:
		///   - status: HTTP status
		public init(_ status: HTTPResponseStatus) {
			self.status = status
			self.headers = [:]
			self.body = nil
		}

		/// Initialize HTTPError
		/// - Parameters:
		///   - status: HTTP status
		///   - message: Associated message
		public init(_ status: HTTPResponseStatus, message: String) {
			self.status = status
			self.headers = ["content-type": "text/plain; charset=utf-8"]
			self.body = message
		}

		/// Get body of error as ByteBuffer
		public func body(allocator: ByteBufferAllocator) -> ByteBuffer? {
			return self.body.map { allocator.buffer(string: $0) }
		}
	}
}

extension WebSocket.HTTPError:CustomStringConvertible {
	/// Description of error for logging
	public var description: String {
		let status = self.status.reasonPhrase
		return "HTTPError: \(status)\(self.body.map { ", \($0)" } ?? "")"
	}
}
