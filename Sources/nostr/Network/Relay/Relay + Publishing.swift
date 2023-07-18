// (c) tanner silva 2023. all rights reserved.

import struct NIO.EventLoopPromise
import protocol NIO.Channel

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

		/// the public-facing relay URL that is being published to
		public let relay:URL
		/// the event UID that is being published
		public let event:nostr.Event.Signed.UID
		/// the promise that will be fulfilled when the relay responds with an OK or not OK
		public let promise:EventLoopPromise<Date>
		
		internal init(relay:URL, event:Event.Signed.UID, channel:Channel) {
			self.relay = relay
			self.event = event
			self.promise = channel.eventLoop.makePromise(of:Date.self)
		}
	}
}