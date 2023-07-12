// (c) tanner silva 2023. all rights reserved.

import RAW
import QuickJSON
import Crypto
import secp256k1

/// the infamous nostr event. this is the core data structure that is used to represent all data in the nostr network.
public struct Event {

	/// represents an event whose contents are mutable prior to signing
	public struct Unsigned:NOSTR_event_unsigned {
		public var kind = Kind.text_note
		public var tags:Tags = []
		public var date:Date? = nil
		public var content = ""

		public init(kind:Kind = .text_note, tags:Tags = [], date:Date? = nil, content:String = "") {
			self.kind = kind
			self.tags = tags
			self.date = date
			self.content = content
		}
	}
	
	/// represents an event whose contents are immutable after signing
	public struct Signed:NOSTR_event_signed {
		/// the unique identifier for the event
		public let uid:UID
		/// the cryptographic signature for the event
		public let sig:Signature
		/// the tags attached to the event
		public let tags:Event.Tags
		/// the author of the event
		public let author:PublicKey
		/// the creation date of the event
		public let date:Date
		/// the kind of event
		public let kind:Kind
		/// the content of the event
		public let content:String

		public init(uid:UID, sig:Signature, tags:Tags, author:PublicKey, date:Date, kind:Kind, content:String) throws {
			self.uid = uid
			self.sig = sig
			self.tags = tags
			self.author = author
			self.date = date
			self.kind = kind
			self.content = content
		}
	}
}

// extension nostr.Event.Signed {
// 	fileprivate func commitment() -> [UInt8] {
// 		let encoder = QuickJSON.Encoder()
// 		let tagsString = String(bytes:try! encoder.encode(tags.compactMap { Array($0) }), encoding:.utf8)!
// 		let contentString = String(bytes:try! encoder.encode(self.content), encoding:.utf8)!
// 		let commit = "[0,\"\(self.pubkey)\",\(Int64(self.created.timeIntervalSinceUnixDate())),\(self.kind.rawValue),\(tagsString),\(contentString)]"
// 		return Array(commit.utf8)
// 	}
// 	public mutating func computeUID() throws {
// 		let commitment = self.commitment()
// 		var hasher = SHA256()
// 		let bytes = commitment.asRAW_val { commitmentVal in
// 			let asBuff = UnsafeRawBufferPointer(start:commitmentVal.mv_data, count:commitmentVal.mv_size)
// 			hasher.update(bufferPointer:asBuff)
// 			return hasher.finalize()
// 		}
// 		self.uid = bytes.withUnsafeBytes { bytesHash in
// 			let asRAW = RAW_val(mv_size:bytesHash.count, mv_data:UnsafeMutableRawPointer(mutating: bytesHash.baseAddress!))
// 			return UID(asRAW)!
// 		}
// 	}
	// public func isValid() -> Bool {
	// 	do {
	// 		let raw_id = SHA256.hash(self.commitment()).asRAW_val { shaHash in
	// 			return UID(shaHash)!
	// 		}
	// 		guard self.uid == raw_id else {
	// 			// the event is not valid if the uid does not match the commitment
	// 			return false
	// 		}
	// 		let sig64 = self.sig.asRAW_val({ rv in
	// 			return Array(rv)
	// 		})
	// 		let ev_pubkey = self.pubkey.asRAW_val({ pkVal in
	// 			return Array(pkVal)
	// 		})
	// 		let ctx = try secp256k1.Context.create()
	// 		var xonly_pubkey = secp256k1_xonly_pubkey.init()
	// 		var ok = secp256k1_xonly_pubkey_parse(ctx, &xonly_pubkey, ev_pubkey)
	// 		guard ok == 1 else {
	// 			// the event is not valid if the pubkey is not valid
	// 			return false
	// 		}
	// 		var raw_id_bytes = raw_id.bytes
	// 		ok = secp256k1_schnorrsig_verify(ctx, sig64, &raw_id_bytes, MemoryLayout<UID>.size, &xonly_pubkey)
	// 		return ok == 1 // the event is valid if sec256k1 returns 1
	// 	} catch {
	// 		return false
	// 	}
	// }
// 	public mutating func sign(_ secKey:SecretKey) throws {
// 		let keyBytes = secKey.asRAW_val({ rawVal in
// 			return Array(rawVal)
// 		})
// 		let key = try secp256k1.Signing.PrivateKey(rawRepresentation:keyBytes)
// 		var aux_rand = try RandomBytes.generate(size: 64)
// 		var digest = self.uid.asRAW_val({
// 			return Array($0)
// 		})
// 		let signature = try key.schnorr.signature(message:&digest, auxiliaryRand:&aux_rand)
// 		signature.rawRepresentation.bytes.asRAW_val({ inputVal in
// 			self.sig = Signature(inputVal)!
// 		})
// 	}
// }

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