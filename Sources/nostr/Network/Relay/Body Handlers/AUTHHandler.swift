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
			case authenticating
			/// the client is authenticated
			case authenticated
		}

		internal enum NOSTR_frame_TYPE:NOSTR_frame {
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

		internal init(keys:KeyPair, relay:URL, okHandler:OKHandler, channel:Channel) {
			self.keys = keys
			self.okHandler = okHandler
			self.url = relay
		}

		static func NOSTR_frame_handler_parse(_ uk:inout UnkeyedDecodingContainer) throws -> NOSTR_frame_TYPE {
			do {
				let challenge = try uk.decode(String.self)
				return .challenge(challenge)
			} catch QuickJSON.Decoder.Error.valueTypeMismatch(let mismatchInfo) {
				switch mismatchInfo.found {
					case .obj:
						let aResponse = try uk.decode(nostr.Event.Signed.self)
						return .assertion(aResponse)
					default:
						throw QuickJSON.Decoder.Error.valueTypeMismatch(mismatchInfo)
				}
			}
		}

	    mutating func NOSTR_frame_handle(_ decoded:NOSTR_frame_TYPE, context: NIOCore.ChannelHandlerContext) throws {
			switch decoded {
				case .challenge(let challengeString):
					#if DEBUG
					Self.logger.trace("got NIP-42 challenge string: \(challengeString)")
					#endif

					/// generate the assertion
					let makeAssertion = try nostr.Event.nip42Assertion(to:challengeString, from:url, using:keys)

					#if DEBUG
					Self.logger.trace("successfully signed assertion: \(makeAssertion.uid.hexEncodedString().prefix(8))")
					#endif

					let newPublishing = Publishing(relay:url, event:makeAssertion.uid, channel:context.channel)
					self.okHandler.addPublishingStruct(newPublishing, for:makeAssertion.uid)

					#if DEBUG
					let writePromise = context.eventLoop.makePromise(of:Void.self)
					context.channel.write(Relay.EncodingFrame(name:"AUTH", contents:[makeAssertion]), promise:writePromise)
					writePromise.futureResult.whenComplete { result in
						switch result {
							case .success(_):
								Self.logger.info("sent nip-42 auth assertion.", metadata: ["response_uid":"\(makeAssertion.uid.description.prefix(8))"])
							case .failure(let error):
								Self.logger.error("failed to send nip-42 auth assertion.", metadata: ["response_uid": "\(makeAssertion.uid.description.prefix(8))", "error": "\(error)"])
						}
					}
					#else
					context.channel.write(Relay.Frame(name:"AUTH", contents:[makeAssertion]), promise:nil)
					#endif
				default:
				fatalError("not supported")
			}
		}
	}
}