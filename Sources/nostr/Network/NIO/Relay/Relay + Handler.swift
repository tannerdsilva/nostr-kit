import NIOCore
import QuickJSON
import Logging

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

extension Relay {
	internal final class Handler:ChannelDuplexHandler, RemovableChannelHandler {
		internal typealias InboundIn = ByteBuffer
		internal typealias InboundOut = Message
		internal typealias OutboundIn = Message
		internal typealias OutboundOut = ByteBuffer

		internal static let logger = makeDefaultLogger(label:"nostr-net:relay-handler", logLevel:.debug)
		// encoder/decoder tools that are allocated and deallocated based on the channel activation
		private var encoder:QuickJSON.Encoder? = nil
		private var decoder:QuickJSON.Decoder? = nil
		private var pool:MemoryPool? = nil
		private var decoderPointer:UnsafeMutableRawPointer? = nil

		// pointer to a buffer that is used to decode inbound data
		private let decodingFlags:QuickJSON.Decoder.Flags
		private let logger:Logger
		private let url:Relay.URL
		private var configuration:Relay.Client.Configuration

		internal init(url:Relay.URL, configuration:Relay.Client.Configuration) {
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
			self.logger.debug("handler added.", metadata: ["read_size": "\(recommendedSize)b"])
			#endif
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
		
		internal func channelInactive(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("channel inactive.")
			#endif
			self.decoder = nil
			self.encoder = nil
			free(self.decoderPointer)
			self.decoderPointer = nil
			self.pool = nil
		}
		internal func handlerRemoved(context:ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("handler removed.")
			#endif
		}
		internal func channelUnregistered(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("channel unregistered.")
			#endif
		}
		internal func channelRegistered(context: ChannelHandlerContext) {
			#if DEBUG
			self.logger.debug("channel registered.")
			#endif
		}
		
		

		internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
			let buffer = self.unwrapInboundIn(data)
			do {
				let capMessage = try buffer.withUnsafeReadableBytes { (bytes:UnsafeRawBufferPointer) in
					try bytes.asRAW_val { rv in
						try self.decoder!.decode(Message.self, from:rv.mv_data, size:rv.mv_size, flags:self.decodingFlags)
					}
				}
				switch capMessage {
					case .authentication(let chal):
						#if DEBUG
						self.logger.debug("received authentication challenge.", metadata: ["challenge": "\(chal)"])
						#endif
						guard self.configuration.authenticationKey != nil else {
							#if DEBUG
							self.logger.error("received authentication challenge but no authentication key is configured.")
							#endif
							context.fireErrorCaught(Error.noAuthenticationKey)
							return
						}
						// build the new event that will respond to the authentication challenge
						var authEvent = nostr.Event()
						authEvent.kind = .auth_response
						authEvent.created = Date()
						authEvent.tags = [
							nostr.Event.Tag(["relay", "\(self.url)"]),
							nostr.Event.Tag(["challenge", "\(chal.prefix(8))"]),
						]
						authEvent.pubkey = self.configuration.authenticationKey!.pubkey
						try authEvent.computeUID()
						try authEvent.sign(self.configuration.authenticationKey!.seckey)
						// encode and send the response
						let encMessage = try encoder!.encode(authEvent)
						var writeBuffer = context.channel.allocator.buffer(capacity:encMessage.count)
						encMessage.asRAW_val({ rawVal in
							_ = writeBuffer.writeBytes(UnsafeRawBufferPointer(start:rawVal.mv_data, count:rawVal.mv_size))
						})
						context.writeAndFlush(self.wrapOutboundOut(writeBuffer), promise:nil)
						#if DEBUG
						self.logger.debug("sent authentication response.", metadata: ["response_uid": "\(authEvent)"])
						#endif
					default:
					break;
				}
				context.fireChannelRead(self.wrapInboundOut(capMessage))
			} catch let error {
				#if DEBUG
				self.logger.error("failed to decode inbound json message.", metadata: ["error": "\(error)"])
				#endif
			}
		}

		internal func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
			let message:Message = self.unwrapOutboundIn(data)
			do {
				let encMessage = try encoder!.encode(message)
				var writeBuffer = context.channel.allocator.buffer(capacity:encMessage.count)
				encMessage.asRAW_val({ rawVal in
					_ = writeBuffer.writeBytes(UnsafeRawBufferPointer(start:rawVal.mv_data, count:rawVal.mv_size))
				})
				context.writeAndFlush(self.wrapOutboundOut(writeBuffer), promise:promise)
			} catch let error {
				#if DEBUG
				self.logger.error("failed to encode outbound json message.", metadata: ["error": "\(error)"])
				#endif
			}
		}
	}
}