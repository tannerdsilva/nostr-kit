extension String {
	mutating func trimExtensionIfExists(_ extnsn:String) {
		if self.count > extnsn.count && self.suffix(extnsn.count) == extnsn {
			// trim the extension from the string
			self = String(self.dropLast(extnsn.count))
		} else {
			// no extension to trim
			return
		}
	}
}