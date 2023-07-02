extension Event {
	public struct Consumer {
		public typealias Handler = (Event) -> Void
		
		private let handler:Handler

		/// 
		public init(handler:@escaping(Handler)) throws {
			self.handler = handler
		}
	}
}