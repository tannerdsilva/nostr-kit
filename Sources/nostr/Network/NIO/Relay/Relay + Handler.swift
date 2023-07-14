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
		internal typealias InboundOut = Message
		internal typealias OutboundIn = Message
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

		/// publishing structs that are currently waiting for an ok response.
		/// - see NIP-20 for more information.
		private var activePublishes:[Event.Signed.UID:Publishing] = [:]

		internal init(url:URL, configuration:Relay.Client.Configuration) {
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
			free(self.decoderPointer)
			self.decoderPointer = nil
			self.pool = nil
			
		}

		internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
			let buffer = self.unwrapInboundIn(data)
			do {
				let capMessage = try buffer.withUnsafeReadableBytes { (bytes:UnsafeRawBufferPointer) in
					try bytes.asRAW_val { rv in
						try self.decoder!.decode(Message.self, from:rv.mv_data, size:rv.mv_size, flags:self.decodingFlags)
					}
				}

				#if DEBUG
				self.logger.trace("got message.", metadata: ["message": "\(capMessage)"])
				#endif

				switch capMessage {
					case .authentication(let stage):
						switch stage {
							case .challenge(let chalStr):
						
							// prepare for authentication process
							guard self.configuration.authenticationKey != nil else {
								#if DEBUG
								self.logger.error("received nip-42 authentication challenge but no authentication key is configured.")
								#endif
								context.fireErrorCaught(Error.noAuthenticationKey)
								return
							}

							#if DEBUG
							self.logger.info("received nip-42 auth challenge.", metadata: ["challenge": "\(chalStr)"])
							#endif

							self.writeNIP42Assertion(challenge:chalStr, context:context, promise:nil)

							case .assertion(_):
							
							#if DEBUG
							self.logger.error("authentication assertion received in client context.")
							#endif
							
							context.fireErrorCaught(Error.authenticationAssertionFound)
							break;
						}
					case let .ok(evUID, didSucceed, message):
						#if DEBUG
						if didSucceed == true {
							self.logger.info("remote peer says 'ok'.", metadata: ["message": "\(message)", "success": "\(didSucceed)", "event_uid": "\(evUID.description.prefix(8))"])
						} else {
							self.logger.error("remote peer says 'not ok'.", metadata: ["message": "\(message)", "success": "\(didSucceed)", "event_uid": "\(evUID.description.prefix(8))"])
						}
						#endif
						if let publishing = self.activePublishes[evUID] {
							switch didSucceed {
								case true:
									#if DEBUG
									self.logger.info("got 'ok' publishing event uid: \(evUID)")
									#endif
									publishing.promise.succeed(Date())
								case false:
									publishing.promise.fail(Publishing.Failure(message:message))
							}
						}
						break;
					default:
					break;
				}
				context.fireChannelRead(self.wrapInboundOut(capMessage))
			} catch let error {
				#if DEBUG
				self.logger.error("failed to decode inbound json message.", metadata: ["error": "\(error)"])
				#endif
				context.fireErrorCaught(error)
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
	/// a struct that is used to track the publishing of an event.
	internal func addPublishingStruct(_ publishing:Relay.Publishing, for evUID:Event.Signed.UID, channel:Channel) -> EventLoopFuture<Void> {
		channel.eventLoop.submit {
			#if DEBUG
			self.logger.debug("adding publishing struct for event uid: \(evUID)")
			#endif
			self.activePublishes[evUID] = publishing
		}
	}
}

extension Relay.Handler {
	/// writes a NIP42 assertion to the remote peer.
	/// - NOTE: this function assumes that there is ALWAYS a valid authentication key in the configuration, and will crash if there is not.
	internal func writeNIP42Assertion(challenge:String, context:ChannelHandlerContext, promise:EventLoopPromise<Void>?) {
		do {
			// generate a new event
			let authEvent = try nostr.Event.nip42Assertion(to:challenge, from:self.url, using: self.configuration.authenticationKey!)
		
			// encode and send the response
			let encMessage = try encoder!.encode(nostr.Relay.Message.authentication(.assertion(authEvent)))

			// write the message to the buffer
			var writeBuffer = context.channel.allocator.buffer(capacity:encMessage.count)
			encMessage.asRAW_val({ rawVal in
				_ = writeBuffer.writeBytes(UnsafeRawBufferPointer(start:rawVal.mv_data, count:rawVal.mv_size))
			})

			// send the buffer into the channel
			#if DEBUG
			let writePromise = context.eventLoop.makePromise(of:Void.self)
			context.writeAndFlush(self.wrapOutboundOut(writeBuffer), promise:writePromise)
			writePromise.futureResult.whenComplete { result in
				switch result {
					case .success(_):
						self.logger.info("sent nip-42 auth assertion.", metadata: ["response_uid":"\(authEvent.uid.description.prefix(8))"])
					case .failure(let error):
						self.logger.error("failed to send nip-42 auth assertion.", metadata: ["response_uid": "\(authEvent.uid.description.prefix(8))", "error": "\(error)"])
				}
			}
			if promise != nil {
				writePromise.futureResult.cascade(to:promise!)
			}
			#else
			context.writeAndFlush(self.wrapOutboundOut(writeBuffer), promise:promise)
			#endif

		
		} catch let error {
			context.fireErrorCaught(error)
		}
	}
}