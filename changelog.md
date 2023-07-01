## v0.3.1

Mostly a bugfix release, with continued buildout under the hood of future features.

- Beginning to implement higher-level integrations with NIP-20 relay messages.

	- `Relay` now has an event writing function that returns a `Published` struct, which can be used to wait for a publishing events "OK" acknowledgement, per NIP-20.

## v0.3.0

Improvements to the entire stack.

- WebSocket handling is now improved. Maximum websocket frame size is now configuratble.

- Relay handling is now improved.

- JSON serialization and deserialization improved.

- NIP-42 is now fully implemented.

- Date improved (no longer able to be influenced by local timezones).

	- Unit test tweaked
	
- Beginning to build out the mechanisms and tools needed around the `Relay.Handler` in order to facilitate more convenient uses in the future.

## v0.2.0

Major buildout of the entire stack. Deep and wide-ranging improvements to every part of the project. The conceptual release is now beginning to look more robust and built out now.

- `nostr-cc` tool beginning to serve basic utilities.

- WebSockets implemented strictly against RFC 6455, with discrete and descriptive errors pertaining to many of the possible violations to the protocol.

- Major changes to public API's and the namespaces (both internal and external) they are oriented around.

- Added more tests.

	- nostr event UID test

	- nostr event signature test

	- nostr key initialize from secret key test (verifies the resulting public key)

## v0.1.0

Conceptual release. Nothing is missing from the library, but not quite usable yet.

- Fully integrates all elements of nostr networking into a single, tightly integrated, high performance library.

	- Networking

	- Parsing

	- Event Handing

	- Cryptography

- Networking & concurrency primarily based on `swift-nio`.

- Designed to run on Linux, iOS (and variants), macOS.
