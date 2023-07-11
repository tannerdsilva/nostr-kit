// (c) tanner silva 2023. all rights reserved.

// used to generate json commitments
import class QuickJSON.Encoder
// used to compute the sha256 hash of the commitment
import struct Crypto.SHA256
// used to generate the event signature
import secp256k1

import RAW

public protocol NOSTR_event {
	/// the date type that is used for the event
	associatedtype NOSTR_event_date_TYPE:NOSTR_date = nostr.Date
	/// the event kind type that is used for the event
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind = nostr.Event.Kind

	/// type for unsigned events
	associatedtype NOSTR_event_unsigned_TYPE:NOSTR_event_unsigned where NOSTR_event_unsigned_TYPE.NOSTR_event_date_TYPE == NOSTR_event_date_TYPE, NOSTR_event_unsigned_TYPE.NOSTR_event_kind_TYPE == NOSTR_event_kind_TYPE
	/// type for signed events
	associatedtype NOSTR_event_signed_TYPE:NOSTR_event_signed = nostr.Event where NOSTR_event_signed_TYPE.NOSTR_event_date_TYPE == NOSTR_event_date_TYPE, NOSTR_event_signed_TYPE.NOSTR_event_kind_TYPE == NOSTR_event_kind_TYPE

	/// sign an unsigned event with the given keypair
	func sign(event unsigned:inout NOSTR_event_unsigned_TYPE, with keypair:KeyPair) throws -> NOSTR_event_signed_TYPE
}

public protocol NOSTR_event_unsigned {
	associatedtype NOSTR_event_date_TYPE:NOSTR_date
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind

	/// the date when the event was created. this value may be nil if the intent is to date this event when it is signed
	var date:NOSTR_event_date_TYPE? { get set }
	/// the tags attached to the event
	var tags:Array<any NOSTR_tag> { get set }
	/// the kind of event
	var kind:NOSTR_event_kind_TYPE { get set }
	/// the content of the event
	var content:String { get set }
}

/// a protocol for expressing a complete nostr event.
public protocol NOSTR_event_signed:Codable {
	associatedtype NOSTR_event_date_TYPE:NOSTR_date
	associatedtype NOSTR_event_kind_TYPE:NOSTR_kind

	/// the unique identifier for the event
	var uid:Event.UID { get }
	/// the cryptographic signature for the event
	var sig:Event.Signature { get }
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
	init(uid:Event.UID, sig:Event.Signature, tags:Event.Tags, author:PublicKey, date:NOSTR_event_date_TYPE, kind:NOSTR_event_kind_TYPE, content:String) throws
		
	/// returns true if the event is cryptographically valid. otherwise, will return false.
	/// - default implementation provided
	func isValid() -> Bool
}

extension NOSTR_event {
	func sign(event unsigned:inout NOSTR_event_unsigned_TYPE, with author:KeyPair) throws -> NOSTR_event_signed_TYPE {
		/// generate the commitment bytes
		let encoder = QuickJSON.Encoder()
		let commit = Event.Commitment(&unsigned, author:author)
		let commitmentBytes = try encoder.encode(commit)

		/// generate the uid based on the commitment
		var hasher = SHA256()
		let bytes = commitmentBytes.asRAW_val { commitmentVal in
			let asBuff = UnsafeRawBufferPointer(start:commitmentVal.mv_data, count:commitmentVal.mv_size)
			hasher.update(bufferPointer:asBuff)
			return hasher.finalize()
		}
		let makeUID = bytes.withUnsafeBytes { bytesHash in
			let asRAW = RAW_val(mv_size:bytesHash.count, mv_data:UnsafeMutableRawPointer(mutating: bytesHash.baseAddress!))
			return Event.UID(asRAW)!
		}

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
			return Event.Signature(inputVal)!
		})
		return try NOSTR_event_signed_TYPE(uid:makeUID, sig:makeSig, tags:unsigned.tags, author:author.publicKey, date:unsigned.date!, kind:unsigned.kind, content:unsigned.content)
	}
}