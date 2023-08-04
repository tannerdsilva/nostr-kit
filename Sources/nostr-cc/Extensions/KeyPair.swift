import nostr
import QuickJSON

import struct Foundation.URL
import struct Foundation.Data

extension KeyPair {
	public func printCLIDescription(showSecretKey:Bool = false, hex:Bool) {
		let pubString:String
		switch hex {
			case true:
				pubString = publicKey.hexEncodedString()
			case false:
				pubString = publicKey.npubString()
		}
		print(Colors.cyan("Public key:"), terminator:"")
		print(" \(pubString)")
		if showSecretKey {
			print(Colors.red("Secret key:"), terminator:"")
			switch hex {
				case true:
					print(" \(secretKey.hexEncodedString())")
				case false:
					print(" \(secretKey.nsecString())")
			}
		}
	}

	public static func fromJSONEncodedPath(_ keyEncodingPath:URL) throws -> nostr.KeyPair {
		let getData = try Data(contentsOf:keyEncodingPath).bytes
		return try QuickJSON.decode(nostr.KeyPair.self, from:getData, size:getData.count)
	}
}