## v0.4.0

- Major changes in how Event tags are structured and expressed in the API.

	- Introduction of new open-ended Tag protocols. There are two high-level protocol expressions of a "nostr tag" in this release.

		- `NOSTR_tag` - a protocol expression of a single tag instance. every instance of this type should have the freedom to express any value in any field (name, index, or additional fields).

		- `NOSTR_tagged` - a protocol that builds upon the concepts of `NOSTR_tag`. however, `NOSTR_tagged` statically links the tag name to each instance of the type. this is useful for "tentpole" structures such as public keys (which ALWAYS encode to "p" tag name).

		These two protocol expressions extend and constrain themselves around the given three sub-procols

		- `NOSTR_tag_name` - expresses a tag name for an instance ("p", "e", even "challenge" or whatever)

		- `NOSTR_tag_index` - the index value for a given tag instance (and the name attached to it). for "e", this would be the hex-encoded value of the event UID.
		
		- `NOSTR_tag_addlfield` - any interpretation of data that may come after the index value of the tag.

- Deprication of Key typealiases for two explicit Key variants: `PublicKey` and `SecretKey` each with slightly different supported protocols.

	- `PublicKey` is `NOSTR_tagged` (a great example of where protocol `NOSTR_tagged` is more apropriate than the alternative that isn't strictly tied to a type: `NOSTR_tag`)

- Broke ground on a new `NOSTR_bech32` protocol for seamless integration with this complex encoding scheme. Still much work to do on this.

- Renamed a func or two in `struct Date` for better consistency with other functions in the struct.

- Replaced signature `String` in `nostr.Event` with more compact `Signature` struct. Occupies half the size in memory.

	- Conforms to the common string-based protocols to ensure accessible string encodings.

- A ton of small changes.

## v0.3.3

- A minor release related to the `nostr-cc`.

	- More rigid/systematic handling of keypair extensions, increasing the likleyhood of keypairs remaining within the scope of `.gitignore`.

## v0.3.2

- New public protocols that allow types to explicitly handle their translations to and from HEX encodings.

	- `HEX_convertible` is an alias for both encoding and decoding protocols.

		- `HEX_encodable` for translating to a hex-encoded string.

		- `HEX_decodable` for translating from a hex-encoded string.

- Changes to `@frozen` structs

	- Additional structs marked as `@frozen`.

		- `nostr.Event.UID` - should always be 32 bytes.

		- `nostr.KeyPair` - should always be 64 bytes (2x 32 byte keys).

	- Frozen structs in the `nostr` library have been moved to a dedicated directory path for better management of their inherit development risks.

- Related to NIP20: `Published` struct now correctly signals failures, as it does successful events.

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

	- Unit test tweaked.
	
- Beginning to build out the mechanisms and tools needed around the `Relay.Handler` in order to facilitate more convenient uses in the future.

## v0.2.0

Major buildout of the entire stack. Deep and wide-ranging improvements to every part of the project. The conceptual release is now beginning to look more robust and built out now.

- `nostr-cc` tool beginning to serve basic utilities.

- WebSockets implemented strictly against RFC 6455, with discrete and descriptive errors pertaining to many of the possible violations to the protocol.

- Major changes to public API's and the namespaces (both internal and external) they are oriented around.

- Added more tests.

	- nostr event UID test.

	- nostr event signature test.

	- nostr key initialize from secret key test (verifies the resulting public key).

## v0.1.0

Conceptual release. Nothing is missing from the library, but not quite usable yet.

- Fully integrates all elements of nostr networking into a single, tightly integrated, high performance library.

	- Networking

	- Parsing

	- Event Handing

	- Cryptography

- Networking & concurrency primarily based on `swift-nio`.

- Designed to run on Linux, iOS (and variants), macOS.
