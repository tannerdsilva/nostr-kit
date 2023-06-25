// (c) tanner silva 2023. all rights reserved.

extension Relay.URL {
	/// Splits up a `Relay.URL` into its necessary components for connecting to a relay.
	internal struct Split {
		/// the host to connect to (ipv4, ipv6, or dns name)
		internal let host:String

		/// the path to connect to
		internal let pathQuery:String

		/// the port to connect to
		internal let port:UInt16

		/// is TLS required when connecting to this relay?
		internal let tlsRequired:Bool

		internal init?(url:Relay.URL) {
			guard let host: String = url.host else { return nil }
			self.host = host
			if let port = url.port {
				self.port = UInt16(port)
			} else {
				if url.scheme == .wss {
					self.port = 443
				} else {
					self.port = 80
				}
			}
			self.tlsRequired = url.scheme == .wss ? true : false
			self.pathQuery = url.path + (url.query.map { "?\($0)" } ?? "")
		}

		/// Return "Host" header value. Only include port if it is different from the default port for the request
		internal var hostHeader: String {
			if (self.tlsRequired && self.port != 443) || (!self.tlsRequired && self.port != 80) {
				return "\(self.host):\(self.port)"
			}
			return self.host
		}
	}

	/// returns a URL.Split from a given URL instance
	internal func split() throws -> Split {
		let makeSplit = Split(url:self)
		guard makeSplit != nil else {
			throw Error.invalidURL
		}
		return makeSplit!
	}
}