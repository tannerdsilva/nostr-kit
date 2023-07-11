import struct NIOCore.TimeAmount
import struct NIOSSL.TLSConfiguration

import cnostr

extension Relay {
	/// a conceptual namespace for client related types
	public struct Client {}
}

extension Relay.Client {
	public struct Configuration {
		/// contains the timeout parameters for the relay connection
		public struct Timeouts {
			/// how much time is allowed to pass as the client attempts to establish a TCP connection to the relay?
			public var tcpConnectionTimeout:TimeAmount = .seconds(3)
			/// how much time is allowed up pass as the client attempts to upgrade the connection to a WebSocket?
			public var websocketUpgradeTimeout:TimeAmount = .seconds(5)
			/// how much time is allowed to pass without a symmetric data exchange being sent between the user and the remote peer?
			/// - this is not a timeout based strictly on an amount of time since the last message was received. this is a timeout interval specifically for the amount of time that can pass without a symmetric data exchange.
			public var websocketConnectionTimeout:TimeAmount = .seconds(15)

			/// initialize a `Timeouts` struct with default values.
			public init() {}
		}
		/// the timeouts for this relay
		public var timeouts:Timeouts

		/// contains the data limit parameters for a relay connection
		public struct Limits {
			/// the maximum websocket frame size.
			public var maxWebSocketFrameSize:size_t = 16777216 // 16mb seems reasonable idk?
			/// initialize a `Limits` struct with default values.
			public init() {}
		}
		/// the data limits for this relay connection
		public var limits:Limits

		/// for connecting to relays that are using NIP-42 authentication, this is the keypair that will be used to solve the challenge string at authentication time
		public var authenticationKey:KeyPair? = nil

		/// the tls configuration for this relay
		public var tlsConfiguration:TLSConfiguration

		/// initialize a new configuration for a relay.
		public init(
			timeouts:Timeouts = Timeouts(),
			limits:Limits = Limits(),
			authenticationKey:KeyPair? = nil,
			tlsConfiguration:TLSConfiguration = TLSConfiguration.makeClientConfiguration()
		) {
			self.timeouts = timeouts
			self.limits = limits
			self.authenticationKey = authenticationKey
			self.tlsConfiguration = tlsConfiguration
		}
	}
}