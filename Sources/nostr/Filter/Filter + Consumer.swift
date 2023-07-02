extension nostr.Filter {
	/// a consumer of events that match a filter.
	public struct Consumer {
		enum Consumable {
			/// a new event that matches the filter.
			case event(nostr.Event)
			/// the end of stored events marker has been reached.
			case eose

			case unsub
		}
	}
}