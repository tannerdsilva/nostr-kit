// (c) tanner silva 2023. all rights reserved.

import QuickJSON

extension Relay {
	/// the nostr message. this is the data structure that relays pass back and forth to their remote peers, and vice versa.
	public enum Message<E:NOSTR_event_signed> {

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
		/// - argument 1: the UID of the event that was acknowledged
		/// - argument 2: whether or not the event was successfully published
		/// - argument 3: a human readable message
		case ok(Event.Signed.UID, Bool, String)

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
		case write(E)

		/// a context used when an event corresponds to a subscription.
		/// - used by clients to consume events from relays.
		/// - used by relays to write requested events to clients.
		case sub(String, E)

		/// initialize an event context from a partially parsed context
		internal init(from container:inout UnkeyedDecodingContainer) throws {
			switch container.count {
				case 2:
					self = .write(try container.decode(E.self))
				case 3:
					let subID = try container.decode(String.self)
					let event = try container.decode(E.self)
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
		public func getEvent() -> E {
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
			case "OK":
				let proof = try container.decode(Event.Signed.UID.self)
				let didSucceed = try container.decode(Bool.self)
				let message = try container.decode(String.self)
				self = .ok(proof, didSucceed, message)
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