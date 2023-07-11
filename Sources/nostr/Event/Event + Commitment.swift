// (c) tanner silva 2023. all rights reserved.

extension Event {

	/// a struct used to represent a commitment to an event. this is a crucial tool used for signing events.
	public struct Commitment:Encodable {
		internal let author:PublicKey
		internal let date:any NOSTR_date
		internal let kind:any NOSTR_kind
		internal let tags:Array<any NOSTR_tag>
		internal let content:String

		/// initialize a new event commitment from an unsigned event and the author that will sign it.
		/// - Parameters:
		///   - unsigned: the unsigned event that will be signed. if the date is nil, the current time will be assigned
		///   - author: the author that will sign the event
		public init<U>(_ unsigned:inout U, author:KeyPair) where U:NOSTR_event_unsigned {
			self.author = author.publicKey
			if unsigned.date == nil {
				unsigned.date = U.NOSTR_event_date_TYPE.currentTime()
			}
			self.date = unsigned.date!
			self.kind = unsigned.kind
			self.tags = unsigned.tags
			self.content = unsigned.content
		}

		/// encode implementation
		public func encode(to encoder:Encoder) throws {
			var container = encoder.unkeyedContainer()
			try container.encode(0)
			try container.encode(author)
			try container.encode(date.NOSTR_date_unixInterval)
			try container.encode(kind)
			var nestedUnkeyedContainer = container.nestedUnkeyedContainer()
			for curTag in tags {
				try nestedUnkeyedContainer.encode(curTag)
			}
			try container.encode(content)
		}
	}
}