// (c) tanner silva 2023. all rights reserved.

extension Relay {
	public enum Consumable {
		/// a new event
		case event(nostr.Event)
		/// the end of stored events has been reached.
		case eose
	}
}