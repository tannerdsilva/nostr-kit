extension Event {
	internal static func nip42Assertion(to challenge:String, from relay:Relay.URL, using keypair:KeyPair) throws -> nostr.Event {
		var authEvent = nostr.Event()
		authEvent.kind = .auth_response
		authEvent.created = Date()
		authEvent.tags = [
			nostr.Event.Tag(["relay", "\(relay)"]),
			nostr.Event.Tag(["challenge", "\(challenge)"]),
		]
		authEvent.pubkey = keypair.pubkey
		try authEvent.computeUID()
		try authEvent.sign(keypair.seckey)
		return authEvent
	}
}