// (c) tanner silva 2023. all rights reserved.

extension Relay {
	public enum Consumable<C:Codable> {
		/// a new event
		case match(C)
		/// the end of stored events has been reached.
		case end
	}
}