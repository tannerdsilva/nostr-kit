import nostr
import QuickJSON

import struct Foundation.URL
import struct Foundation.Data

extension KeyPair {
	public func printCLIDescription(showSecretKey:Bool = false) {
		let npubString = pubkey.npubString()
		print(Colors.cyan("Public key:"), terminator:"")
		print(" \(npubString)")
		if showSecretKey {
			print(Colors.red("Secret key:"), terminator:"")
			print(" \(seckey.nsecString())")
		}
	}

	public static func fromJSONEncodedPath(_ keyEncodingPath:URL, decoder:QuickJSON.Decoder? = nil) throws -> nostr.KeyPair {
		let decObj:QuickJSON.Decoder
		if decoder == nil { 
			decObj = QuickJSON.Decoder()
		} else {
			decObj = decoder!
		}
		let getData = try Data(contentsOf:keyEncodingPath).bytes
		return try decObj.decode(nostr.KeyPair.self, from:getData)
	}
}