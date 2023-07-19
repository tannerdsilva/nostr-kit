import class NIO.ChannelHandlerContext
import class NIO.EventLoopFuture
import class QuickJSON.Encoder

#if DEBUG
import Logging
#endif 

extension Relay {
	internal struct OKHandler:NOSTR_frame_handler {
		internal struct NOSTR_frame_TYPE:NOSTR_frame {
			let eventUID:Event.Signed.UID
			let didSucceed:Bool
			let message:String

			let NOSTR_frame_name = "OK"

			var NOSTR_frame_contents:[any Codable] {
				return [self.eventUID, self.didSucceed, self.message]
			}
		}

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
		}

		/// parse a given frame
		internal static func NOSTR_frame_handler_parse(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_frame_TYPE {
			return NOSTR_frame_TYPE(eventUID:try uk.decode(Event.Signed.UID.self), didSucceed:try uk.decode(Bool.self), message:try uk.decode(String.self))
		}

		/// MUST be called within the event loop
		internal mutating func NOSTR_frame_handle(_ decoded:NOSTR_frame_TYPE, context:NIOCore.ChannelHandlerContext) throws {
			#if DEBUG
			if decoded.didSucceed == true {
				self.logger.debug("remote peer says 'ok'.", metadata: ["message": "\(decoded.message)", "success": "\(decoded.didSucceed)", "event_uid": "\(decoded.eventUID.description.prefix(8))"])
			} else {
				self.logger.error("remote peer says 'not ok'.", metadata: ["message": "\(decoded.message)", "success": "\(decoded.didSucceed)", "event_uid": "\(decoded.eventUID.description.prefix(8))"])
			}
			#endif

			// get the publishing struct
			if let publishing = self.activePublishes[decoded.eventUID] {
				switch decoded.didSucceed {
					case true:
						#if DEBUG
						self.logger.trace("passing 'success' to found publishing struct...")
						#endif
						publishing.promise.succeed(Date())
					case false:
						#if DEBUG
						self.logger.trace("passing 'failure' to found publishing struct...")
						#endif
						publishing.promise.fail(Publishing.Failure(message:decoded.message))
				}
				self.activePublishes.removeValue(forKey:decoded.eventUID)
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