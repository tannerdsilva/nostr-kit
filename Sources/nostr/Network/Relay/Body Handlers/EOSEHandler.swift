import NIO

extension Relay {
	internal class EOSEHandler:NOSTR_frame_handler {
		private var eoseActions:[String:(String) -> Void]

		internal init() {
			self.eoseActions = [:]
		}

		internal func NOSTR_frame_handler_decode_inbound(_ uk: inout UnkeyedDecodingContainer, context:ChannelHandlerContext) throws {
			let sid = try uk.decode(String.self)
			let checkAction = eoseActions.removeValue(forKey:sid)
			if checkAction != nil {
				checkAction!(sid)
				return
			}
			#if DEBUG
			logger.warning("received EOSE for unknown subscription '\(sid)'.")
			#endif
		}

		/// register an action to fire for a particular subscription id
		/// - WARNING: MUST be called within the event loop
		internal func registerEOSEAction(_ sid:String, _ action:@escaping (String) -> Void) {
			self.eoseActions[sid] = action
		}

		/// remove an action to fire for a particular subscription id
		/// - WARNING: MUST be called within the event loop
		internal func deregisterEOSEAction(_ sid:String) {
			self.eoseActions[sid] = nil
		}
	}
}