// (c) tanner silva 2023. all rights reserved.

// used to generate json commitments
import class QuickJSON.Encoder
// used to compute the sha256 hash of the commitment
import struct Crypto.SHA256
// used to generate the event signature
import secp256k1

import RAW

public protocol NOSTR_event_unsigned {
	associatedtype NOSTR_event_date_TYPE:NOSTR_date = nostr.Date
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind = nostr.Event.Kind

	/// the date when the event was created. this value may be nil if the intent is to date this event when it is signed
	var date:NOSTR_event_date_TYPE? { get set }
	/// the tags attached to the event
	var tags:Array<any NOSTR_tag> { get set }
	/// the kind of event
	var kind:NOSTR_event_kind_TYPE { get set }
	/// the content of the event
	var content:String { get set }

	/// initialize a new instance of the unsigned event based on the unsigned content of this instance and the given author.
	/// this function will mutate the given unsigned event if its date is nil. a nil date is a convenience feature for developers to specify that the content should be dated at sign time.
	/// - default implementation provided.
	mutating func sign<S>(to signedType:S.Type, as author:KeyPair) throws -> S where S:NOSTR_event_signed, S.NOSTR_event_date_TYPE == NOSTR_event_date_TYPE, S.NOSTR_event_kind_TYPE == NOSTR_event_kind_TYPE
}

/// a protocol for expressing a complete nostr event.
public protocol NOSTR_event_signed:Codable {
	associatedtype NOSTR_event_date_TYPE:NOSTR_date = nostr.Date
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind = nostr.Event.Kind

	/// the unique identifier for the event
	var uid:Event.Signed.UID { get }
	/// the cryptographic signature for the event
	var sig:Event.Signed.Signature { get }
	/// the tags attached to the event
	var tags:Event.Tags { get }
	/// the author of the event
	var author:PublicKey { get }
	/// the creation date of the event
	var date:NOSTR_event_date_TYPE { get }
	/// the kind of event
	var kind:NOSTR_event_kind_TYPE { get }
	/// the content of the event
	var content:String { get }

	/// initialize a new instance of the signed event based on the given parameters.
	/// - required implementation provided
	init(uid:Event.Signed.UID, sig:Event.Signed.Signature, tags:Event.Tags, author:PublicKey, date:NOSTR_event_date_TYPE, kind:NOSTR_event_kind_TYPE, content:String) throws
}

/// default codable implementation
extension NOSTR_event_signed {
	public init(from decoder:Swift.Decoder) throws {
		var container = try decoder.unkeyedContainer()
		let uid = try container.decode(Event.Signed.UID.self)
		let sig = try container.decode(Event.Signed.Signature.self)
		var tagsArr = try container.nestedUnkeyedContainer()
		var tags = Event.Tags()
		while !tagsArr.isAtEnd {
			tags.append(try tagsArr.decode(nostr.Event.Tag.self))
		}
		let author = try container.decode(PublicKey.self)
		let date = try container.decode(UInt64.self)
		let kind = try container.decode(NOSTR_event_kind_TYPE.self)
		let content = try container.decode(String.self)
		self = try Self(uid:uid, sig:sig, tags:tags, author:author, date:NOSTR_event_date_TYPE(NOSTR_date_unixInterval:date), kind:kind, content:content)
	}
	public func encode(to encoder:Swift.Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(uid)
		try container.encode(sig)
		var tagsArr = container.nestedUnkeyedContainer()
		for curTag in tags {
			try tagsArr.encode(curTag)
		}
		try container.encode(author)
		try container.encode(date.NOSTR_date_unixInterval)
		try container.encode(kind)
		try container.encode(content)
	}
}

extension NOSTR_event_unsigned {
	public mutating func sign<S>(to signedType:S.Type, as author:KeyPair) throws -> S where S:NOSTR_event_signed, S.NOSTR_event_date_TYPE == NOSTR_event_date_TYPE, S.NOSTR_event_kind_TYPE == NOSTR_event_kind_TYPE {
		// generate the commitment bytes
		let encoder = QuickJSON.Encoder()
		let commit = Event.Commitment(unsigned:&self, author:author)
		let commitmentBytes = try encoder.encode(commit)
		
		// generate the uid based on the commitment
		var hasher = SHA256()
		let bytes = commitmentBytes.asRAW_val { commitmentVal in
			let asBuff = UnsafeRawBufferPointer(start:commitmentVal.mv_data, count:commitmentVal.mv_size)
			hasher.update(bufferPointer:asBuff)
			return hasher.finalize()
		}
		let makeUID = bytes.withUnsafeBytes { bytesHash in
			let asRAW = RAW_val(mv_size:bytesHash.count, mv_data:UnsafeMutableRawPointer(mutating: bytesHash.baseAddress!))
			return Event.Signed.UID(asRAW)!
		}
		
		// sign with the private key
		let keyBytes = author.secretKey.asRAW_val({ rawVal in
			return Array(rawVal)
		})
		let key = try secp256k1.Signing.PrivateKey(rawRepresentation:keyBytes)
		var aux_rand = try RandomBytes.generate(size: 64)
		var digest = makeUID.asRAW_val({
			return Array($0)
		})
		let signature = try key.schnorr.signature(message:&digest, auxiliaryRand:&aux_rand)
		let makeSig = signature.rawRepresentation.bytes.asRAW_val({ inputVal in
			return Event.Signed.Signature(inputVal)!
		})
		return try S(uid:makeUID, sig:makeSig, tags:tags, author:author.publicKey, date:date!, kind:kind, content:content)
	}
}

extension NOSTR_event_signed {
	public func isValid() -> Bool {
		do {
			// generate the commitment bytes
			let newComm = nostr.Event.Commitment(signed:self)
			let encoder = QuickJSON.Encoder()
			let commBytes = try encoder.encode(newComm)

			// hash the commitment
			let raw_id = SHA256.hash(Array(commBytes)).asRAW_val { shaHash in
				return Event.Signed.UID(shaHash)!
			}
			guard self.uid == raw_id else {
				// the event is not valid if the uid does not match the commitment
				return false
			}
			let sig64 = self.sig.asRAW_val({ rv in
				return Array(rv)
			})
			let ev_pubkey = self.author.asRAW_val({ pkVal in
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
			ok = secp256k1_schnorrsig_verify(ctx, sig64, &raw_id_bytes, MemoryLayout<Event.Signed.UID>.size, &xonly_pubkey)
			return ok == 1 // the event is valid if sec256k1 returns 1
		} catch {
			return false
		}
	}
}