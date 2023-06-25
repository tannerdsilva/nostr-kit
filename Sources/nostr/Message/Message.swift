// (c) tanner silva 2023. all rights reserved.

extension Relay {
	/// the nostr message. much like the ``nostr.Event`` being the single struct that populates all data throughout 
	public enum Message {

		/// subscription message (with attached metadata)
		case subscribe(SubscribeInfo)
		/// unsubscription message (containing the subscription ID)
		case unsubscribe(String)

		/// event message
		/// - when this case is being written outbound, the `String` value is ignored and can be set to `""`
		/// - when this case is being read inbound, the `String` value is the subscription ID that surfaced the event
		case event(String, Event)

		/// sent by relays to mark the end of a stored event dump
		case endOfStoredEvents(String)

		/// an acknowledgement of a message
		case ok(String)

		/// an authentication challenge containing a challenge string
		case authentication(String)
	}
}

extension Relay.Message {
	public struct SubscribeInfo:Codable {
		/// the subscription ID
		public var sub_id:String

		/// the filters that will match events to this subscription
		public var filters:Set<Filter>
	}
}

extension Relay.Message:Codable {
	public init(from decoder:Decoder) throws {
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
				let subID = try container.decode(String.self)
				let event = try container.decode(Event.self)
				self = .event(subID, event)
			case "EOSE":
				let subID = try container.decode(String.self)
				self = .endOfStoredEvents(subID)
			case "AUTH":
				let authChallenge = try container.decode(String.self)
				self = .authentication(authChallenge)
			case "OK":
				let proof = try container.decode(String.self)
				self = .ok(proof)
		default:
			throw Error.unknownRequestInstruction(type)
		}
	}
	public func encode(to encoder:Encoder) throws {
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
			case .event(_, let event):
				try container.encode("EVENT")
				try container.encode(event)
			case .endOfStoredEvents(let subID):
				try container.encode("EOSE")
				try container.encode(subID)
			case .authentication(let challenge):
				try container.encode("AUTH")
				fatalError("idk what to do here yet")
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