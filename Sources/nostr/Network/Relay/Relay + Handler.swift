import NIOCore
import QuickJSON
import Logging

import cnostr

extension Relay {

	/// handles primary nostr functionality for a client connection to a relay.
	/// - implements NIP-01 parsing (JSON encoding and decoding)
	/// - implements NIP-42 with automatic authentication
	/// - implements NIP-20 for handling the results of publishing events
	internal final class Handler:ChannelDuplexHandler, RemovableChannelHandler {
		internal typealias InboundIn = ByteBuffer
		internal typealias InboundOut = Message<nostr.Event.Signed>
		internal typealias OutboundIn = Frame
		internal typealias OutboundOut = ByteBuffer

		internal static let logger = makeDefaultLogger(label:"nostr-net:relay-handler", logLevel:.info)
		
		// encoder/decoder tools that are allocated and deallocated based on the channel activation
		private var encoder:QuickJSON.Encoder? = nil
		private var decoder:QuickJSON.Decoder? = nil
		private var pool:MemoryPool? = nil
		private var decoderPointer:UnsafeMutableRawPointer? = nil
		// pointer to a buffer that is used to decode inbound data

		private let decodingFlags:QuickJSON.Decoder.Flags
		private let logger:Logger
		private let url:URL
		private var configuration:Relay.Client.Configuration

		/// the current frame handlers that are handling the frontline logistics of the various nostr messages
		private var okHandler:OKHandler? = nil

		internal init(url:URL, configuration:Relay.Client.Configuration, types:NOSTR_frame_nametypes.Type, channel:Channel) {
			var makeLogger = Self.logger
			makeLogger[metadataKey:"url"] = "\(url)"
			self.logger = makeLogger
			self.decodingFlags = QuickJSON.Decoder.Flags()
			self.url = url
			self.configuration = configuration
			#if DEBUG
			makeLogger.trace("instance initialized.")
			#endif
		}

		internal func handlerAdded(context: ChannelHandlerContext) {
			let recommendedSize = QuickJSON.MemoryPool.maxReadSize(inputSize:self.configuration.limits.maxWebSocketFrameSize, flags:QuickJSON.Decoder.Flags())
			#if DEBUG
			self.logger.info("relay connected.", metadata: ["parse_buff_size": "\(recommendedSize) bytes"])
			#endif

			// this malloc is freed in handlerRemoved
			self.decoderPointer = malloc(recommendedSize)

			do {
				let memPool = try QuickJSON.MemoryPool.allocate(staticSize:recommendedSize, staticBuffer: self.decoderPointer!)
				self.decoder = QuickJSON.Decoder(memory:memPool)
				self.encoder = QuickJSON.Encoder()
			} catch let error {
				#if DEBUG
				self.logger.error("failed to allocate memory pool.", metadata: ["error": "\(error)"])
				#endif
				context.close(promise:nil)
			}
		}
		
		internal func handlerRemoved(context:ChannelHandlerContext) {
			#if DEBUG
			self.logger.trace("relay disconnected.")
			#endif
			self.decoder = nil
			self.encoder = nil

			// frees the malloc from handlerAdded
			free(self.decoderPointer)

			self.decoderPointer = nil
			self.pool = nil
		}

		internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
			let buffer = self.unwrapInboundIn(data)
			do {
				let capMessage = try buffer.withUnsafeReadableBytes { (bytes:UnsafeRawBufferPointer) in
					try bytes.asRAW_val { rv in
						try self.decoder!.decode(Message<nostr.Event.Signed>.self, from:rv.mv_data, size:rv.mv_size, flags:self.decodingFlags)
					}
				}

				#if DEBUG
				self.logger.trace("got message.", metadata: ["message": "\(capMessage)"])
				#endif

				

			} catch let error {
				#if DEBUG
				self.logger.error("failed to decode inbound json message.", metadata: ["error": "\(error)"])
				#endif
				context.fireErrorCaught(error)
			}
		}

		internal func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
			let message = self.unwrapOutboundIn(data)
			do {
				let encMessage = try encoder!.encode(message)
				var writeBuffer = context.channel.allocator.buffer(capacity:encMessage.count)
				encMessage.asRAW_val({ rawVal in
					_ = writeBuffer.writeBytes(UnsafeRawBufferPointer(start:rawVal.mv_data, count:rawVal.mv_size))
				})
				context.writeAndFlush(self.wrapOutboundOut(writeBuffer), promise:promise)
				#if DEBUG
				self.logger.trace("encoded outbound json message.")
				#endif
			} catch let error {
				#if DEBUG
				self.logger.error("failed to encode outbound json message.", metadata: ["error": "\(error)"])
				#endif
				context.fireErrorCaught(error)
			}
		}
	}
}

extension Relay.Handler {
	internal func addPublishingStruct(_ publishing:Relay.Publishing, for evUID:Event.Signed.UID) {
		self.channel.eventLoop.submit {
			self.okHandler!.addPublishingStruct(publishing, for:evUID)
		}
	}

}