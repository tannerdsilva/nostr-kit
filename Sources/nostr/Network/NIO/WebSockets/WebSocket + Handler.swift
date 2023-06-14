import NIOCore
import NIOWebSocket
import Logging
#if os(macOS)
import struct Darwin.size_t
#elseif os(Linux)
import struct Glibc.size_t
#endif

extension WebSocket {
	
	/// sequence of fragmented WebSocket frames. ``WebSocket.Handler`` uses this to combine fragmented frames into a single buffer
	internal struct FrameSequence {
		/// type of sequence
		internal enum SequenceType {
			/// text frame
			case text
			/// binary frame
			case binary
			/// returns opcode for sequence type
			internal func opcode() -> WebSocketOpcode {
				switch self {
					case .text:
					return .text
					case .binary:
					return .binary
				}
			}
		}
		
		/// buffers containing frames
		internal var buffers:[ByteBuffer]
		/// total size of sequence
		internal var size:size_t
		/// type of sequence
		internal var type:SequenceType
		/// the maximum number of bytes that are allowed to pass through the handler
		internal var byteLimit:size_t

		/// create a new sequence
		internal init(type:SequenceType = .binary, byteLimit:size_t = 10240) {
			self.buffers = []
			self.type = type
			self.size = 0
			self.byteLimit = byteLimit
		}
		
		/// append a frame to the sequence
		internal mutating func append(_ frame: WebSocketFrame) {
			assert(frame.opcode == self.type.opcode())
			self.buffers.append(frame.unmaskedData)
			self.size += frame.unmaskedData.readableBytes
		}

		/// combines all of the frames into a single buffer
		internal func exportCombinedResult() -> ByteBuffer {
			var result = ByteBufferAllocator().buffer(capacity: self.size)
			for var buffer in self.buffers {
				result.writeBuffer(&buffer)
			}
			return result
		}
	}

	/// handles the merging of WebSocket frames into a single data type for the user
	/// - abstracts ping/pong logic entirely.
	/// - abstracts away the fragmentation of WebSocket frames
	/// - abstracts away frame types. a default written frame type can be specified, however, all inbound data is treated the same (as a ByteBuffer)
	internal final class Handler:ChannelDuplexHandler {
		// duplex types
		typealias InboundIn = WebSocketFrame
		typealias InboundOut = ByteBuffer
		typealias OutboundIn = ByteBuffer
		typealias OutboundOut = WebSocketFrame
		
		// this handler internalizes the ping/pong logic
		private var waitingOnPong: Bool = false
		private var autoPingTask: Scheduled<Void>?
		private var pingData:ByteBuffer? = nil
		// buffer data
		private var webSocketFrameSequence:FrameSequence? = nil

		/// the url that the relay is connected to
		internal let url:Relay.URL
		
		/// which operation will be used when writing data to the websocket?
		internal let writeOp:WebSocketOpcode

		/// the maximum number of bytes that are allowed to pass through the handler
		internal let byteLimit:size_t

		#if DEBUG
		/// logger for this instance
		internal let logger:Logger
		#endif

		internal init(url:URL, writeOp:WebSocketOpcode = .text, byteLimit:size_t = 10240) {
			self.url = url
			self.writeOp = writeOp
			self.byteLimit = byteLimit
			
			#if DEBUG
			var makeLogger = WebSocket.logger
			makeLogger[metadataKey:"url"] = "\(url)"
			self.logger = makeLogger
			#endif
		}

		/// initiates auto ping functionality on the connection. 
		internal func initiateAutoPing(channel: Channel, interval: TimeAmount) {
			self.autoPingTask = channel.eventLoop.scheduleTask(in: interval) {
				if self.waitingOnPong {
					// we never received a pong from our last ping, so the connection has timed out
					let promise = channel.eventLoop.makePromise(of: Void.self)
					channel.close(promise: promise)
				} else {
					self.sendPing(channel: channel).whenSuccess {
						self.waitingOnPong = true
						self.initiateAutoPing(channel: channel, interval: interval)
					}
				}
			}
		}
		
		/// sends a ping to the server
		internal func sendPing(channel: Channel) -> EventLoopFuture<Void> {
			let random = (0..<16).map { _ in UInt8.random(in: 0...255) }
			self.pingData!.clear()
			self.pingData!.writeBytes(random)
			let newFrame = WebSocketFrame(fin: true, opcode: .ping, data: self.pingData!)
			let writeandFlushFuture = channel.writeAndFlush(self.wrapOutboundOut(newFrame))

			#if DEBUG
			return writeandFlushFuture.always { result in
				switch result {
					case .success:
					self.logger.debug("sent ping.")
					break
					case .failure(let error):
					self.logger.error("failed to send ping: '\(error)'")
				}
			}
			#else
			return writeandFlushFuture
			#endif
		}

		/// activation hook
		internal func channelActive(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("channel active.")
			#endif
			self.pingData = context.channel.allocator.buffer(capacity: 16)
			self.initiateAutoPing(channel: context.channel, interval: .seconds(10))
		}

		/// deactivation hook
		internal func channelInactive(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("channel inactive.")
			#endif
			self.autoPingTask?.cancel()
			self.autoPingTask = nil
			self.pingData = nil
		}

		/// read hook
		internal func channelRead(context:ChannelHandlerContext, data:NIOAny) {
			let frame: InboundIn = self.unwrapInboundIn(data)
			switch frame.opcode {
			case .pong:
				guard frame.data == self.pingData else {
					context.channel.close(mode:.all, promise: nil)
					return
				}
				self.waitingOnPong = false
				#if DEBUG
				self.logger.debug("received pong.")
				#endif
			case .ping:
				guard frame.fin else {
					context.channel.close(mode:.all, promise: nil)
					return
				}
				let responsePong = WebSocketFrame(fin:true, opcode:.pong, data:frame.data)
				context.writeAndFlush(self.wrapOutboundOut(responsePong), promise:nil)
				#if DEBUG
				self.logger.debug("received ping...now sending pong in response.")
				#endif
			case .text:
				if var frameSeq = self.webSocketFrameSequence {
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				} else {
					var frameSeq = FrameSequence(type:.text)
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				}
			case .binary:
				if var frameSeq = self.webSocketFrameSequence {
					frameSeq.append(frame)
					self.webSocketFrameSequence = frameSeq
				} else {
					var frameSeq = FrameSequence(type:.binary)
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

			// handles a complete frame sequence
			if let frameSeq = self.webSocketFrameSequence, frame.fin {
				if frameSeq.size < self.byteLimit {
					context.fireChannelRead(self.wrapInboundOut(frameSeq.exportCombinedResult()))
				} else {
					#if DEBUG
					self.logger.notice("frame sequence exceeded byte limit of \(self.byteLimit).")
					#endif
				}
				self.webSocketFrameSequence = nil
			}
		}

		// write hook
		internal func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
			let message:ByteBuffer = self.unwrapOutboundIn(data)
			let frame = WebSocketFrame(fin: true, opcode:self.writeOp, data: message)
			context.write(self.wrapOutboundOut(frame), promise: promise)
		}
	}
}