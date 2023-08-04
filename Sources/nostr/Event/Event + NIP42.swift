// (c) tanner silva 2023. all rights reserved.

extension Event {
	internal static func nip42Assertion(to challenge:String, from relay:URL, using keypair:KeyPair) throws -> nostr.Event.Signed {
		var authEvent = nostr.Event.Unsigned(kind:.auth_response)
		authEvent.tags = [
			["challenge", challenge],
			["relay", relay.description],
		]
		return try authEvent.sign(type:nostr.Event.Signed.self, as:keypair)
	}
}