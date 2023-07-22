import class NIO.ChannelHandlerContext
import class NIO.EventLoopFuture
import class QuickJSON.Encoder

#if DEBUG
import Logging
#endif 

extension Relay {
	internal struct OKHandler:NOSTR_frame_handler {
		#if DEBUG
		internal let logger:Logger
		#endif

		private let url:URL

		/// publishing structs that are currently waiting for an ok response.
		/// - see NIP-20 for more information.
		private var activePublishes:[Event.Signed.UID:Publishing]

		internal init(url:URL) {
			self.activePublishes = [:]
			#if DEBUG
			self.logger = makeDefaultLogger(label:"nostr-net:frame-handler:OK", url:url, logLevel:.debug)
			#endif
			self.url = url
		}

		/// parse a given frame
		internal mutating func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			let decUID = try uk.decode(Event.Signed.UID.self)
			let didSuc = try uk.decode(Bool.self)
			let gotMsg = try uk.decode(String.self)
			
			#if DEBUG
			if didSuc == true {
				self.logger.debug("remote peer says 'ok'.", metadata: ["message": "\(gotMsg)", "success": "\(didSuc)", "event_uid": "\(decUID.description.prefix(8))"])
			} else {
				self.logger.error("remote peer says 'not ok'.", metadata: ["message": "\(gotMsg)", "success": "\(didSuc)", "event_uid": "\(decUID.description.prefix(8))"])
			}
			#endif

			// get the publishing struct
			if let publishing = self.activePublishes[decUID] {
				switch didSuc {
					case true:
						#if DEBUG
						self.logger.trace("passing 'success' to found publishing struct...")
						#endif
						publishing.promise.succeed(Date())
					case false:
						#if DEBUG
						self.logger.trace("passing 'failure' to found publishing struct...")
						#endif
						publishing.promise.fail(Publishing.Failure(message:gotMsg))
				}
				self.activePublishes.removeValue(forKey:decUID)
			}
		}

		/// MUST be called within the event loop.
		internal mutating func addPublishingStruct(_ publishing:Relay.Publishing, for evUID:Event.Signed.UID) {
			activePublishes[evUID] = publishing
		}
	}
}

extension Relay.OKHandler {
	public enum Error:Swift.Error {
		case invalidFrameBody
	}
}