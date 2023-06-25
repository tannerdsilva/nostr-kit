import struct NIOWebSocket.WebSocketOpcode

extension Relay {
	/// these are all the front-facing errors that a developer may encouter when using the relay
	public enum Error:Swift.Error {

		/// relay errors pertaining to the websocket protocol
		public enum WebSocket:Swift.Error {

			/// various types of RFC 6455 violations that may occur at any point during a connection lifecycle.
			public enum RFC6455Violation:Swift.Error {
				
				/// describes various ways that a websocket can violate the fragment control rules defined in RFC 6455 section 5.4.
				public enum FragmentControlViolation {
					/// a ping frame was received from the remote peer, but the ping data was to be delivered with a fragment flag, which is invalid.
					/// - NOTE: see RFC 6455 section 5.4 & 5.5 for more information.
					case fragmentedPingReceived

					/// a pong frame was received from the remote peer, but the pong data was to be delivered with a fragment flag, which is invalid.
					/// - NOTE: see RFC 6455 section 5.4 & 5.5 for more information.
					case fragmentedPongReceived

					/// continued data was received from the remote peer, but the continued data fragments were not of the same type as the initial data fragment.
					/// - NOTE: see RFC 6455 section 5.4 for more information.
					case steamOpcodeMismatch(WebSocketOpcode, WebSocketOpcode)

					/// a continued frame was received from the remote peer, but there was no previous frame to continue.
					/// - NOTE: see RFC 6455 section 5.4 for more information.
					case continuationWithoutContext

					/// a new websocket data stream was initated from the remote peer, but there was already existing data being handled by the connection.
					/// - NOTE: see RFC 6455 section 5.4 for more information.
					case initiationWithUnfinishedContext
				}

				/// the remote peer sent a ping that was longer than the required maximum of 125 bytes.
				/// - NOTE: see RFC 6455 section 5.5 for more information.
				case pingPayloadTooLong

				/// the remote peer sent a pong that was longer than the required maximum of 125 bytes.
				/// - NOTE: see RFC 6455 section 5.5 for more information.
				case pongPayloadTooLong

				/// thrown when a pong response from the remote peer did not contain the expected payload. this is considered an internal and unexpected failure.
				///	- argument 1: the expected payload that was sent to the remote peer.
				///	- argument 2: the pong response that was received after sending the ping.
				/// - NOTE: see RFC 6455 section 5.5 for more information.
				case pongPayloadMismatch([UInt8], [UInt8])

				/// thrown when the fragment control rules defined in RFC 6455 section 5.4 are violated.
				case fragmentControlViolation(FragmentControlViolation)
			}

			/// thrown when a websocket connection is successfully initiated with a relay, but the initial ping could not be written. this is considered an internal and unexpected failure. it is not expected to be thrown under healthy and normal system conditions.
			/// - argument: contains the underlying error that caused the failure.
			case failedToWriteInitialPing(Swift.Error)

			/// the configured timeout interval for the established connection could not be sustained with websocket pings.
			case connectionTimeout

			/// an event occurred that fell out of line with RFC 6455 specifications.
			case rfc6455Violation(RFC6455Violation)
		}

		/// thrown when a URL could not be parsed into an actionable address.
		case invalidURL(URL)

		case connectionBootstrapError

		case noAuthenticationKey
	}
}