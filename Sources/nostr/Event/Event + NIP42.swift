extension Event {
	internal static func nip42Assertion(to challenge:String, from relay:Relay.URL, using keypair:KeyPair) throws -> nostr.Event {
		var authEvent = nostr.Event()
		authEvent.kind = .auth_response
		authEvent.created = Date()
		authEvent.tags = [
			["relay", relay.description],
			["challenge", challenge],
		]
		authEvent.pubkey = keypair.pubkey
		try authEvent.computeUID()
		try authEvent.sign(keypair.seckey)
		return authEvent
	}
}