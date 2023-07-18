import class NIO.ChannelHandlerContext
import class NIO.EventLoopFuture
import class QuickJSON.Encoder

extension Relay {
	internal struct OKHandler:NOSTR_frame_body {

		internal struct Frame {
			let eventUID:Event.Signed.UID
			let didSucceed:Bool
			let message:String
		}

		#if DEBUG
		internal let logger = makeDefaultLogger(label:"nostr-net:relay-handler:OK", logLevel:.debug)
		#endif

		/// publishing structs that are currently waiting for an ok response.
		/// - see NIP-20 for more information.
		private var activePublishes:[Event.Signed.UID:Publishing]

		internal init() {
			self.activePublishes = [:]
		}

		static func parseBody(_ uk:inout UnkeyedDecodingContainer) throws -> Frame {
			return Frame(eventUID:try uk.decode(Event.Signed.UID.self), didSucceed:try uk.decode(Bool.self), message:try uk.decode(String.self))
		}

		/// MUST be called within the event loop
		mutating func handleDecodedBody(_ decoded:Frame, context:NIOCore.ChannelHandlerContext) throws {
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
						publishing.promise.succeed(Date())
					case false:
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