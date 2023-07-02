import NIO

extension Relay {
	
	/// used to track track the OK response from a relay when publishing an event.
	/// - see nostr nip-20 for more details.
	public struct Publishing {
		/// represents a direct response from the relay explaining the circumstances of the failed publish.
		public struct Failure:Swift.Error {
			public let message:String
		}

		/// represents a failure of the network connection to the relay. this failure came before the results of the publish were received.
		public struct NetworkFailure:Swift.Error {
			public let error:Swift.Error
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