// (c) tanner silva 2023. all rights reserved.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import RAW
import secp256k1

extension KeyPair {
	enum Errow:Swift.Error {
		/// thrown when initializing a keypair from a secret key that is invalid
		case invalidSecretKey
	}
}

/// a pairing of public and private keys.
@frozen public struct KeyPair {
	/// public key of the keypair
	public let pubkey:PublicKey
	
	/// private key of the keypair
	public let seckey:SecretKey

	/// initialize a keypair from an existing secret key.
	/// - throws: `KeyPair.Errow.invalidSecretKey` if the secret key is invalid
	public init(seckey:SecretKey) throws {
		do {
			let getKeys = try seckey.asRAW_val { rval in
				let secRaw = try secp256k1.Signing.PrivateKey(rawRepresentation:Array(rval))
				let getBytes = secRaw.publicKey.xonly.bytes
				let pubkey = getBytes.asRAW_val({ rawVal in
					return PublicKey(rawVal)!
				})
				let secK = secRaw.rawRepresentation.bytes.asRAW_val { secVal in
					return SecretKey(secVal)!
				}
				return (pubkey, secK)
			}
			self.pubkey = getKeys.0
			self.seckey = getKeys.1
		} catch {
			throw KeyPair.Errow.invalidSecretKey
		}
	}
	
	/// initialize a keypair from an existing public and private key pair
	public init(pubkey:PublicKey, seckey:SecretKey) {
		self.pubkey = pubkey
		self.seckey = seckey
	}

	/// generate a new keypair
	public static func generateNew() throws -> Self {
		let genesis: secp256k1.Signing.PrivateKey = try secp256k1.Signing.PrivateKey()
		let privKey = genesis.rawRepresentation.bytes.asRAW_val({ keyVal in
			return SecretKey(keyVal)!
		})
		let pubKey = genesis.publicKey.xonly.bytes.asRAW_val({ keyVal in
			return PublicKey(keyVal)!
		})
		return KeyPair(pubkey:pubKey, seckey:privKey)
	}
}

extension KeyPair:RAW_convertible {
	// RAW_convertible
	public init?(_ value: RAW_val) {
		guard value.mv_size == MemoryLayout<Self>.size else {
			return nil
		}
		self = value.mv_data!.assumingMemoryBound(to: Self.self).pointee
	}
	public func asRAW_val<R>(_ valFunc: (inout RAW_val) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self, { unsafePointer in
			var val = RAW_val(mv_size:MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
			return try valFunc(&val)
		})
	}
}

extension KeyPair:RAW_comparable {
	// Lexigraphical sorting here
	public static let rawCompareFunction:@convention(c) (UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 = { a, b in
		let aData = a!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		let bData = b!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
		
		let minLength = min(a!.pointee.mv_size, b!.pointee.mv_size)
		let comparisonResult = memcmp(aData, bData, minLength)

		if comparisonResult != 0 {
			return Int32(comparisonResult)
		} else {
			// If the common prefix is the same, compare their lengths.
			return Int32(a!.pointee.mv_size) - Int32(b!.pointee.mv_size)
		}
	}
}

extension KeyPair:Codable {
	// Codable
	public init(from decoder:Decoder) throws {
		let container = try decoder.container(keyedBy:CodingKeys.self)
		let pubkey = try container.decode(PublicKey.self, forKey:.pubkey)
		let seckey = try container.decode(SecretKey.self, forKey:.seckey)
		self.init(pubkey:pubkey, seckey:seckey)
	}
	public func encode(to encoder:Encoder) throws {
		var container = encoder.container(keyedBy:CodingKeys.self)
		try container.encode(self.pubkey, forKey:.pubkey)
		try container.encode(self.seckey, forKey:.seckey)
	}
}

extension KeyPair:Equatable, Hashable, Comparable {
	// Equatable
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) == 0
			})
		})
	}
	
	// Comparable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.asRAW_val({ lhsVal in
			return rhs.asRAW_val({ rhsVal in
				return Self.rawCompareFunction(&lhsVal, &rhsVal) < 0
			})
		})
	}

	// Hashable
	public func hash(into hasher:inout Hasher) {
		withUnsafePointer(to:self) { byteBuff in
			for i in 0..<MemoryLayout<Self>.size {
				hasher.combine(byteBuff.advanced(by: i))
			}
		}
	}
}

fileprivate enum CodingKeys:String, CodingKey {
	case pubkey = "pubkey"
	case seckey = "seckey"
}