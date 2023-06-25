import nostr

/// Profile is a struct that represents a user's profile on Nostr
struct Profile:Codable {
	struct Wallets: Codable, Hashable {
		var btc: String? = nil
		var ltc: String? = nil
		var xmr: String? = nil

		enum CodingKeys: String, CodingKey {
			case btc = "bitcoin"
			case ltc = "litecoin"
			case xmr = "monero"
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(btc)
			hasher.combine(ltc)
			hasher.combine(xmr)
		}
		
		func isEmpty() -> Bool {
			if (btc == nil || btc!.count == 0) && (xmr == nil || xmr!.count == 0) && (ltc == nil || ltc!.count == 0) {
				return true
			} else {
				return false
			}
		}
	}

	/// name of the profile
	var name:String? = nil
	/// display name of the profile
	var display_name:String? = nil
	/// is the profile deleted?
	var deleted:Bool? = nil
	/// biography of the profile
	var about:String? = nil
	/// profile picture
	var picture:String? = nil
	/// profile banner photo
	var banner:String? = nil
	/// website url of the profile
	var website:String? = nil
	/// lnurl-pay address
	var lud06:String? = nil
	/// lnurl-pay address
	var lud16:String? = nil
	/// nip05 verification address
	var nip05:String? = nil
	/// wallets associated with the profile
	var wallets:Wallets? = nil
}