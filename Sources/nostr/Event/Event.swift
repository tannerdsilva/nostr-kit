// (c) tanner silva 2023. all rights reserved.

import RAW
import QuickJSON
import secp256k1

/// the infamous nostr event. this is the core data structure that is used to represent all data in the nostr network.
public struct Event {

	/// represents an event whose contents are mutable prior to signing
	public struct Unsigned:NOSTR_event_unsigned {
		public var kind = Kind.text_note.rawValue
		public var tags:Tags = []
		public var date:Date? = nil
		public var content = ""

		public init(kind:UInt64, tags:Tags = [], date:Date? = nil, content:String = "") {
			self.kind = kind
			self.tags = tags
			self.date = date
			self.content = content
		}
	}

	public struct Encrypted {

		// public struct NIP_04:NOSTR_event_signed {
		// 	public let uid:Event.Signed.UID
		// 	public let sig:Event.Signed.Signature
		// 	public let tags:Tags
		// 	public let author:PublicKey
		// 	public let recipient:PublicKey
		// 	public let date:Date
		// 	public let kind:Kind
		// 	public let content:String
		// }
	}
	
	/// represents an event whose contents are immutable after signing
	public struct Signed:NOSTR_event_signed {
		/// the unique identifier for the event
		public let uid:UID
		/// the cryptographic signature for the event
		public let sig:Signature
		/// the tags attached to the event
		public let tags:Event.Tags
		/// the author of the event
		public let author:PublicKey
		/// the creation date of the event
		public let date:Date
		/// the kind of event
		public let kind:UInt64
		/// the content of the event
		public let content:String

		public init(uid:UID, sig:Signature, tags:Tags, author:PublicKey, date:Date, kind:UInt64, content:String) throws {
			self.uid = uid
			self.sig = sig
			self.tags = tags
			self.author = author
			self.date = date
			self.kind = kind
			self.content = content
		}
	}
}

/// coding keys for nostr.Event
extension nostr.Event {
	
	/// the standard coding keys for the event
	internal enum CodingKeys:String, CodingKey {
		case uid = "id"
		case sig = "sig"
		case tags = "tags"
		case author = "pubkey"
		case date = "created_at"
		case kind = "kind"
		case content = "content"
	}
}