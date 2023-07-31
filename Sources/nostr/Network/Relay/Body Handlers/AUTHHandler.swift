import NIO
import class QuickJSON.Encoder
import class QuickJSON.Decoder

extension Relay {

	internal struct AUTHHandler:NOSTR_frame_handler {

		#if DEBUG
		internal static let logger = makeDefaultLogger(label:"nostr-net:relay-handler:AUTH", logLevel:.debug)
		#endif

		internal enum State {
			/// the client has not yet authenticated with the relay
			case unauthenticated
			/// the client is in the process of authenticating with the relay
			case authenticating(EventLoopPromise<Date>)
			/// the client is authenticated
			case authenticated(Date)
		}

		fileprivate enum AuthStage:NOSTR_frame {
			/// represents the challenge stage of the authentication scheme
			/// - argument 1: the challenge string
			case challenge(String)

			/// the assertion stage of the authentication scheme.
			/// - argument 1: the signed authentication proof event
			case assertion(nostr.Event.Signed)

			/// the authentication has completed successfully.
			var NOSTR_frame_name:String {
				return "AUTH"
			}
			var NOSTR_frame_contents:[any Codable] {
				switch self {
					case .challenge(let challenge):
						return [challenge]
					case .assertion(let aResponse):
						return [aResponse]
				}
			}
		}

		// allows us to register a handler for when the authentication is complete
		private var okHandler:OKHandler

		internal let url:URL
		fileprivate let keys:KeyPair

		internal var stateHandler:(State) -> Void

		internal init(keys:KeyPair, relay:URL, okHandler:OKHandler, channel:Channel, stateHandler:@escaping (State) -> Void) {
			self.keys = keys
			self.okHandler = okHandler
			self.url = relay
			self.stateHandler = stateHandler
		}

		internal mutating func NOSTR_frame_handler_decode_inbound(_ uk:inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			let authStage:AuthStage
			do {
				let challenge = try uk.decode(String.self)
				authStage = .challenge(challenge)
			} catch QuickJSON.Decoder.Error.valueTypeMismatch(let mismatchInfo) {
				switch mismatchInfo.found {
					case .obj:
						let aResponse = try uk.decode(nostr.Event.Signed.self)
						authStage = .assertion(aResponse)
					default:
						throw QuickJSON.Decoder.Error.valueTypeMismatch(mismatchInfo)
				}
			}

			switch authStage {
				case .challenge(let challengeString):
					#if DEBUG
					Self.logger.trace("got NIP-42 challenge string: \(challengeString)")
					#endif

					/// generate the assertion
					let makeAssertion = try nostr.Event.nip42Assertion(to:challengeString, from:url, using:keys)

					#if DEBUG
					Self.logger.trace("successfully signed assertion: \(makeAssertion.uid.hexEncodedString().prefix(8))")
					#endif

					let writePromise = context.eventLoop.makePromise(of:Void.self)
					context.channel.write(Relay.EncodingFrame(name:"AUTH", contents:[makeAssertion]), promise:writePromise)
					writePromise.futureResult.whenComplete { [sh = self.stateHandler, okh = self.okHandler] result in
						switch result {
							case .success(_):
								#if DEBUG
								Self.logger.info("sent nip-42 auth assertion.", metadata: ["response_uid":"\(makeAssertion.uid.description.prefix(8))"])
								#endif
								let promise = okh.createNIP20Promise(for:makeAssertion.uid)
								sh(.authenticating(promise))
								
							case .failure(let error):
								Self.logger.error("failed to send nip-42 auth assertion.", metadata: ["response_uid": "\(makeAssertion.uid.description.prefix(8))", "error": "\(error)"])
						}
					}
				default:
				fatalError("authentication assetion events not supported on this socket")
			}
		}
	}
}