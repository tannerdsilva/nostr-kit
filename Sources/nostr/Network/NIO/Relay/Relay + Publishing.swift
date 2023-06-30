import NIO

extension Relay {
	/// used to track the state of a publishing event
	public struct Publishing {
		public let relay:Relay.URL
		public let event:String
		public let promise:EventLoopPromise<Date>

		init(relay:Relay.URL, event:String, promise:EventLoopPromise<Date>) {
			self.relay = relay
			self.event = event
			self.promise = promise
		}
	}
}