import struct NIOSSL.TLSConfiguration
import NIO

import cnostr

extension Relay {
	/// a conceptual namespace for client related types
	public struct Client {}
}

extension Relay.Client {

	/// a structure used to configure the concurrency resources for the relay client.
	public struct Loops {
		/// this is the event loop that drives activity directly related to the system socket (NIO channel).
		/// - includes parsing data off the socket and matching the resulting to types
		public let channel:EventLoop

		/// this is the event loop that does the cryptographic verification of incoming events.
		/// - mostly, this event loop does the work of verifying event signatures from scratch.
		/// - optionally, can call a 
		public let verify:EventLoop

		/// initialize a new loop configuration for a relay.
		public init(channel:EventLoop, verify:EventLoop) {
			self.channel = channel
			self.verify = verify
		}

		/// initialize a new loop configuration with a grouped event loop provider.
		public init(multiThreadedEventLoopGroup:MultiThreadedEventLoopGroup) {
			self.channel = multiThreadedEventLoopGroup.next()
			self.verify = multiThreadedEventLoopGroup.next()
		}
	}
}

extension Relay.Client {
	/// contains the timeout parameters for the relay connection
	public struct Timeouts {
		/// how much time is allowed to pass as the client attempts to establish a TCP connection to the relay?
		public let tcpConnectionTimeout:TimeAmount
		/// how much time is allowed up pass as the client attempts to upgrade the connection to a WebSocket?
		public let websocketUpgradeTimeout:TimeAmount
		/// how much time is allowed to pass without a symmetric data exchange being sent between the user and the remote peer?
		/// - this is not a timeout based strictly on an amount of time since the last message was received. this is a timeout interval specifically for the amount of time that can pass without a symmetric data exchange.
		public let healthyConnectionTimeout:TimeAmount

		/// initialize a `Timeouts` struct.
		public init(
			tcpConnectionTimeout:TimeAmount = .seconds(3),
			websocketUpgradeTimeout:TimeAmount = .seconds(5),
			healthyConnectionTimeout:TimeAmount = .seconds(15)
		) {
			self.tcpConnectionTimeout = tcpConnectionTimeout
			self.websocketUpgradeTimeout = websocketUpgradeTimeout
			self.healthyConnectionTimeout = healthyConnectionTimeout
		}
	}
}

extension Relay.Client {
	/// contains the data limit parameters for a relay connection
	public struct Limits {
		/// the maximum websocket frame size.
		public var maxWebSocketFrameSize:size_t

		public init(maxWebSocketFrameSize:size_t = 16777216) {
			self.maxWebSocketFrameSize = maxWebSocketFrameSize
		}
	}
}

extension Relay.Client {
	public struct Configuration {

		/// the timeouts for this relay
		public var timeouts:Timeouts

		/// the data limits for this relay connection
		public var limits:Limits

		/// the event loops for this relay
		public var loops:Loops

		/// for connecting to relays that are using NIP-42 authentication, this is the keypair that will be used to solve the challenge string at authentication time
		public var authenticationKey:KeyPair? = nil

		/// the tls configuration for this relay
		public var tlsConfiguration:TLSConfiguration

		/// the amount of time that an inbound event will be held before being sent to the user.
		public var eventHoldTime:TimeAmount = .milliseconds(250)

		/// initialize a new configuration for a relay.
		public init(
			timeouts:Timeouts = Timeouts(),
			limits:Limits = Limits(),
			authenticationKey:KeyPair? = nil,
			tlsConfiguration:TLSConfiguration = TLSConfiguration.makeClientConfiguration(),
			loops:Loops = Loops(multiThreadedEventLoopGroup:MultiThreadedEventLoopGroup(numberOfThreads:System.coreCount))
		) {
			self.timeouts = timeouts
			self.limits = limits
			self.authenticationKey = authenticationKey
			self.tlsConfiguration = tlsConfiguration
			self.loops = loops
		}
	}
}