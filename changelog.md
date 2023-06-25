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