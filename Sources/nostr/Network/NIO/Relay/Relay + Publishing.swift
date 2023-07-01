import NIO

extension Relay {
	
	/// used to track track the OK response from a relay when publishing an event.
	/// - see nostr nip-20 for more details.
	public struct Publishing {
		/// represents a failure to publish an event to a relay.
		public struct Failure:Swift.Error {
			public let message:String
		}
		
		public let relay:Relay.URL
		public let event:String
		public let promise:EventLoopPromise<Date>
		
		internal init(relay:Relay.URL, event:String, channel:Channel) {
			self.relay = relay
			self.event = event
			self.promise = channel.eventLoop.makePromise(of:Date.self)
		}
	}
}