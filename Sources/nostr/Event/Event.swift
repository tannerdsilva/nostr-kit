// (c) tanner silva 2023. all rights reserved.

import RAW
import QuickJSON
import Crypto
import secp256k1

/// the infamous nostr event. this is the core data structure that is used to represent all data in the nostr network.
public struct Event {
	/// the unique identifier for the event
	public var uid:UID = UID()
	/// the cryptographic signature for the event
	public var sig:Signature = Signature()
	/// the tags attached to the event
	public var tags = Tags()
	/// the author of the event
	public var pubkey = PublicKey()
	/// the creation date of the event
	public var created = Date()
	/// the kind of event
	public var kind = Kind.text_note
	/// the content of the event
	public var content:String = ""

	/// initialize a new event
	public init() {}
}

extension nostr.Event {
	fileprivate func commitment() -> [UInt8] {
		let encoder = QuickJSON.Encoder()
		let tagsString = String(bytes:try! encoder.encode(tags.compactMap { Array($0) }), encoding:.utf8)!
		let contentString = String(bytes:try! encoder.encode(self.content), encoding:.utf8)!
		let commit = "[0,\"\(self.pubkey)\",\(Int64(self.created.timeIntervalSinceUnixDate())),\(self.kind.rawValue),\(tagsString),\(contentString)]"
		return Array(commit.utf8)
	}
	public mutating func computeUID() throws {
		let commitment = self.commitment()
		var hasher = SHA256()
		let bytes = commitment.asRAW_val { commitmentVal in
			let asBuff = UnsafeRawBufferPointer(start:commitmentVal.mv_data, count:commitmentVal.mv_size)
			hasher.update(bufferPointer:asBuff)
			return hasher.finalize()
		}
		self.uid = bytes.withUnsafeBytes { bytesHash in
			let asRAW = RAW_val(mv_size:bytesHash.count, mv_data:UnsafeMutableRawPointer(mutating: bytesHash.baseAddress!))
			return UID(asRAW)!
		}
	}
	public func isValid() -> Bool {
		do {
			let raw_id = SHA256.hash(self.commitment()).asRAW_val { shaHash in
				return UID(shaHash)!
			}
			guard self.uid == raw_id else {
				// the event is not valid if the uid does not match the commitment
				return false
			}
			let sig64 = self.sig.asRAW_val({ rv in
				return Array(rv)
			})
			let ev_pubkey = self.pubkey.asRAW_val({ pkVal in
				return Array(pkVal)
			})
			let ctx = try secp256k1.Context.create()
			var xonly_pubkey = secp256k1_xonly_pubkey.init()
			var ok = secp256k1_xonly_pubkey_parse(ctx, &xonly_pubkey, ev_pubkey)
			guard ok == 1 else {
				// the event is not valid if the pubkey is not valid
				return false
			}
			var raw_id_bytes = raw_id.bytes
			ok = secp256k1_schnorrsig_verify(ctx, sig64, &raw_id_bytes, MemoryLayout<UID>.size, &xonly_pubkey)
			return ok == 1 // the event is valid if sec256k1 returns 1
		} catch {
			return false
		}
	}
	public mutating func sign(_ secKey:SecretKey) throws {
		let keyBytes = secKey.asRAW_val({ rawVal in
			return Array(rawVal)
		})
		let key = try secp256k1.Signing.PrivateKey(rawRepresentation:keyBytes)
		var aux_rand = try RandomBytes.generate(size: 64)
		var digest = self.uid.asRAW_val({
			return Array($0)
		})
		let signature = try key.schnorr.signature(message:&digest, auxiliaryRand:&aux_rand)
		signature.rawRepresentation.bytes.asRAW_val({ inputVal in
			self.sig = Signature(inputVal)!
		})
	}
}

/// coding keys for nostr.Event
extension nostr.Event {
	
	/// the standard coding keys for the event
	internal enum CodingKeys:String, CodingKey {
		case uid = "id"
		case sig = "sig"
		case tags = "tags"
		case author = "pubkey"
		case date = "created_at"
		case kind = "kind"
		case content = "content"
	}
}