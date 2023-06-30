// (c) tanner silva 2023. all rights reserved.

import QuickJSON

extension Relay {
	/// the nostr message. this is the data structure that relays pass back and forth to their remote peers, and vice versa.
	public enum Message {

		/// subscription message (with attached metadata).
		case subscribe(SubscribeInfo)
		/// unsubscription message (containing the subscription ID).
		case unsubscribe(String)

		/// event message.
		/// - when this case is being read inbound, the `String` value is the subscription ID that surfaced the event
		case event(EventContext)

		/// sent by relays to mark the end of a stored event dump.
		case endOfStoredEvents(String)

		/// an acknowledgement of a message.
		case ok(String)

		/// an authentication challenge containing a challenge string.
		/// - see nostr nip-42 for more information.
		case authentication(AuthStage)

		/// used to send human readable messages to the other side.
		case notice(String)
	}
}

extension Relay.Message {

	/// used to describe the context in which an event may be handled in a relay channel
	public enum EventContext {

		/// thrown when an "EVENT" message is handled in the channel but the containing array had an unexpected number of elements.
		public struct ParseError:Swift.Error {}

		/// an event context used for writing.
		/// - used by clients to write events to a relay.
		/// - used by relays to parse events from clients.
		case write(nostr.Event)

		/// a context used when an event corresponds to a subscription.
		/// - used by clients to consume events from relays.
		/// - used by relays to write requested events to clients.
		case sub(String, nostr.Event)

		/// initialize an event context from a partially parsed context
		internal init(from container:inout UnkeyedDecodingContainer) throws {
			switch container.count {
				case 2:
					self = .write(try container.decode(nostr.Event.self))
				case 3:
					let subID = try container.decode(String.self)
					let event = try container.decode(nostr.Event.self)
					self = .sub(subID, event)
				default:
					throw ParseError()
			}
		}

		/// encode the event context to a partially encoded context
		internal func encode(to container:inout UnkeyedEncodingContainer) throws {
			switch self {
				case .write(let event):
					try container.encode(event)
				case .sub(let subID, let event):
					try container.encode(subID)
					try container.encode(event)
			}
		}

		/// returns the enclosed event regardless of context
		public func getEvent() -> nostr.Event {
			switch self {
				case .write(let event):
					return event
				case .sub(_, let event):
					return event
			}
		}
	}
}

extension Relay.Message {
	public enum AuthStage {
		/// represents the challenge stage of the authentication scheme
		/// - argument 1: the challenge string
		case challenge(String)

		/// the assertion stage of the authentication scheme.
		/// - argument 1: the signed authentication proof event
		case assertion(nostr.Event)
	}
}

extension Relay.Message {
	public struct SubscribeInfo:Codable {
		/// the subscription ID
		public var sub_id:String

		/// the filters that will match events to this subscription
		public var filters:Set<Filter>

		/// initialize a new SubscribeInfo struct.
		public init(sub_id:String, filters:Set<Filter>) {
			self.sub_id = sub_id
			self.filters = filters
		}
	}
}

extension Relay.Message:Codable {
	public init(from decoder:Swift.Decoder) throws {
		var container = try decoder.unkeyedContainer()
		let type = try container.decode(String.self)
		switch type.uppercased() {
			case "REQ":
				let sub_id = try container.decode(String.self)
				var filters = [Filter]()
				while container.isAtEnd == false {
					filters.append(try container.decode(Filter.self))
				}
				self = .subscribe(SubscribeInfo(sub_id: sub_id, filters:Set(filters)))
			case "CLOSE":
				let sub_id = try container.decode(String.self)
				self = .unsubscribe(sub_id)
			case "EVENT":
				let context = try EventContext(from: &container)
				self = .event(context)
			case "EOSE":
				let subID = try container.decode(String.self)
				self = .endOfStoredEvents(subID)
			case "AUTH":
				do {
					let challenge = try container.decode(String.self)
					self = .authentication(.challenge(challenge))
				} catch QuickJSON.Decoder.Error.valueTypeMismatch(let mismatchInfo) {
					switch mismatchInfo.found {
						case .obj:
							let aResponse = try container.decode(nostr.Event.self)
							self = .authentication(.assertion(aResponse))
						default:
							throw QuickJSON.Decoder.Error.valueTypeMismatch(mismatchInfo)
					}
				}
			case "OK":
				let proof = try container.decode(String.self)
				self = .ok(proof)
			case "NOTICE":
				let notice = try container.decode(String.self)
				self = .notice(notice)
			default:
				throw Error.unknownRequestInstruction(type)
		}
	}
	public func encode(to encoder:Swift.Encoder) throws {
		var container = encoder.unkeyedContainer()
		switch self {
			case .subscribe(let sub):
				try container.encode("REQ")
				try container.encode(sub.sub_id)
				for cur_filter in sub.filters {
					try container.encode(cur_filter)
				}
			case .unsubscribe(let sub_id):
				try container.encode("CLOSE")
				try container.encode(sub_id)
			case .event(let evContext):
				try container.encode("EVENT")
				try evContext.encode(to:&container)
			case .endOfStoredEvents(let subID):
				try container.encode("EOSE")
				try container.encode(subID)
			case .authentication(let aStage):
				try container.encode("AUTH")
				switch aStage {
					case .challenge(let chal):
						try container.encode(chal)
					case .assertion(let proof):
						try container.encode(proof)
				}
			case .notice(let chal):
				try container.encode("NOTICE")
				try container.encode(chal)
			default:
				break;
		}
	}
}

extension Relay.Message {
	public enum Error:Swift.Error {
		case unknownRequestInstruction(String)
	}
}