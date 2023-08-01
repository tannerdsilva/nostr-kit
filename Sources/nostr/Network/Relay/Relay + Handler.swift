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
		internal typealias OutboundIn = EncodingFrame
		internal typealias OutboundOut = ByteBuffer

		internal static let logger = makeDefaultLogger(label:"nostr-net:relay-handler", logLevel:.info)
		
		// encoder/decoder tools that are allocated and deallocated based on the channel activation
		private var pool:QuickJSON.Memory.Region? = nil					// the memory region that is used to decode inbound data

		private let decodingFlags:QuickJSON.Decoding.Flags				// the decoding flags that are used to decode inbound data
		private let logger:Logger										// the logger for this handler

		/// the url to the remote peer
		private let url:URL

		/// the configuration that this handler is operating with
		private var configuration:Relay.Client.Configuration

		/// the channel that this handler is attached to
		private let channel:Channel

		/// the current frame handlers that are handling the frontline logistics of the various nostr messages
		private let allFrameHandlerNames:Set<String>
		private let handlers:[String:any NOSTR_frame_handler]
		/// typed reference for the OK frame handler. this is also stored in `handlers` but this is a convenience variable
		internal var okHandler:OKHandler
		/// typed reference for the AUTH frame handler. this is also stored in `handlers` but this is a convenience variable
		internal var authHandler:AUTHHandler? = nil

		internal init(url:URL, configuration:Relay.Client.Configuration, channel:Channel, handlers:[String:any NOSTR_frame_handler]) {
			var makeLogger = Self.logger
			makeLogger[metadataKey:"url"] = "\(url)"
			self.logger = makeLogger
			self.decodingFlags = QuickJSON.Decoding.Flags()
			self.url = url
			self.configuration = configuration
			#if DEBUG
			makeLogger.trace("instance initialized.")
			#endif
			self.channel = channel
			self.handlers = handlers
			self.okHandler = handlers["OK"] as! Relay.OKHandler
			self.authHandler = handlers["AUTH"] as? Relay.AUTHHandler
			self.allFrameHandlerNames = Set(handlers.keys)
		}

		internal func handlerAdded(context: ChannelHandlerContext) {
			#if DEBUG
			defer {
				self.logger.info("relay connected.")
			}
			#endif

			// this malloc is freed in handlerRemoved
			do {
				let memory = try Memory.Region(maximumReadingSize:self.configuration.limits.maxWebSocketFrameSize)
				self.pool = memory
			} catch let error {
				#if DEBUG
				self.logger.error("failed to allocate memory pool.", metadata:["error": "\(error)"])
				#endif
				context.close(promise:nil)
			}
		}
		
		internal func handlerRemoved(context:ChannelHandlerContext) {
			#if DEBUG
			defer {
				self.logger.trace("relay disconnected.")
			}
			#endif
			self.pool = nil
		}

		internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
			let buffer = self.unwrapInboundIn(data)
			do {
				 try buffer.withUnsafeReadableBytes { (bytes:UnsafeRawBufferPointer) in
					try QuickJSON.decode(data:bytes.baseAddress!, size:buffer.readableBytes, flags:self.decodingFlags, memory:.preallocated(self.pool!)) { getVal in
						var getArray = try getVal.unkeyedContainer()
						let firstName = try getArray.decode(String.self)
						if self.allFrameHandlerNames.contains(firstName) {
							#if DEBUG
							self.logger.trace("received frame.", metadata: ["frame": "\(firstName)"])
							#endif
							try handlers[firstName]!.NOSTR_frame_handler_decode_inbound(&getArray, context:context)
						} else {
							#if DEBUG
							self.logger.error("received unknown frame.", metadata: ["frame": "\(firstName)"])
							#endif
						}
					}
				}
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
				let encMessage = try QuickJSON.encode(message)
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