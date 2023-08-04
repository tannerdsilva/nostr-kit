import QuickJSON

import NIO

#if DEBUG
import Logging
#endif 

extension Relay {
	/// thrown when a publish failes, with a message describing the failure if provided.
	public struct PublishFailure:Swift.Error {
		public let message:String
	}

	/// the OK frame handler.
	/// - manages the OK frames that are sent by the remote peer for each event instance
	/// - also manages the timeouts for each event instance and their executions
	internal class OKHandler:NOSTR_frame_handler {
		#if DEBUG
		internal let logger:Logger
		#endif

		private let url:URL

		private let channel:Channel

		/// publishing structs that are currently waiting for an ok response.
		/// - see NIP-20 for more information.
		private var activePublishes:[Event.Signed.UID:EventLoopPromise<Date>]

		internal init(url:URL, channel:Channel) {
			self.activePublishes = [:]
			#if DEBUG
			self.logger = makeDefaultLogger(label:"nostr-net:frame-handler:OK", url:url, logLevel:.debug)
			#endif
			self.url = url
			self.channel = channel
		}

		/// parse a given frame
		internal func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			// complete decoding
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

			// get the promise
			if let publishing = self.activePublishes[decUID] {
				switch didSuc {
					case true:
						#if DEBUG
						self.logger.trace("passing 'success' to found publishing struct...")
						#endif
						publishing.succeed(Date())
					case false:
						#if DEBUG
						self.logger.trace("passing 'failure' to found publishing struct...")
						#endif
						publishing.fail(PublishFailure(message:gotMsg))
				}
				self.activePublishes.removeValue(forKey:decUID)
			}
		}

		internal func createNIP20Promise(for eventUID:Event.Signed.UID) -> EventLoopPromise<Date> {
			let promise = self.channel.eventLoop.makePromise(of:Date.self)
			self.activePublishes[eventUID] = promise
			#if DEBUG
			self.logger.debug("registered new publishing struct for event uid '\(eventUID.description.prefix(8))'.")
			#endif
			return promise
		}

		/// cancel an existing NIP-20 promise. avoid using this function where possible. a NIP20 promise should not be created until it is certain that it is needed.
		internal func cancelNIP20Promise(for eventUID:Event.Signed.UID) -> EventLoopPromise<Date> {
			let getPromise = self.activePublishes.removeValue(forKey:eventUID)!
			#if DEBUG
			self.logger.debug("canceled promise for event uid '\(eventUID.description.prefix(8))'.")
			#endif
			return getPromise
		}
	}
}

extension Relay.OKHandler {
	public enum Error:Swift.Error {
		case invalidFrameBody
	}
}