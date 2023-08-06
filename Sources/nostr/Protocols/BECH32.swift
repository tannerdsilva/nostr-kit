// (c) tanner silva 2023. all rights reserved.

import RAW
import cnostr

public protocol NOSTR_bech32_multi_decodable:NOSTR_bech32_hrp, NOSTR_bech32_decodable {
	static var NOSTR_bech32_multi_decodable_TYPES:[UInt8:RAW_decodable.Type] { get }
	init(NOSTR_bech32_multi_values:[(UInt8, RAW_decodable)]) throws
}

extension NOSTR_bech32_multi_decodable {
	public init(NOSTR_bech32_encoded:String) throws {
		let decoded = try Self.NOSTR_bech32_hrp_decode(NOSTR_bech32_encoded:NOSTR_bech32_encoded)
		var i = 0
		let values = try decoded.asRAW_val { decodedBuff -> [(UInt8, RAW_decodable)] in
			var buildValues = [(UInt8, RAW_decodable)]()
			while i < decodedBuff.mv_size {
				let type = decodedBuff.mv_data.load(fromByteOffset:i, as:UInt8.self)
				i += 1 // increment past the type byte
				let swiftType = Self.NOSTR_bech32_multi_decodable_TYPES[type]
				let elsize = Int(decodedBuff.mv_data.load(fromByteOffset:i, as:UInt8.self))
				i += 1 // increment past the size byte
				guard elsize <= (decodedBuff.mv_size - i) else {
					throw Bech32.Errors.InvalidElementLength(body:decoded, body_index:i, element_expected_length:size_t(elsize))
				}
				let rawVal = RAW_val(mv_size:elsize, mv_data:decodedBuff.mv_data.advanced(by:i))
				i += elsize // increment past the value bytes
				guard swiftType != nil else {
					continue
				}
				let val = swiftType!.init(rawVal)
				if val != nil {
					buildValues.append((type, val!))
				}
			}
			return buildValues
		}
		self = try Self.init(NOSTR_bech32_multi_values:values)
	}
}

/// this is a protocol that is used to define a type that can be encoded to a bech32 string.
public protocol NOSTR_bech32_multi_encodable:NOSTR_bech32_encodable {
	func NOSTR_bech32_multi_encode() -> [(UInt8, any RAW_convertible)]
}

extension NOSTR_bech32_multi_encodable {
	public func NOSTR_bech32_encode(hrp:String) -> String {
		let encoded = self.NOSTR_bech32_multi_encode()
		var buildBytes = [UInt8]()
		for valType in encoded {
			buildBytes.append(valType.0)
			valType.1.asRAW_val { rawVal in
				assert(rawVal.mv_size <= 255)
				buildBytes.append(UInt8(rawVal.mv_size))
				buildBytes.append(contentsOf:rawVal)
			}
		}
		return buildBytes.asRAW_val {
			return Bech32.encode(hrp:hrp, $0)
		}
	}
}

/// UInt8 is used for bech32 raw encoding so that protocol needs to be implemented here.
extension UInt8:RAW_convertible {
	public func asRAW_val<T>(_ closure:(inout RAW_val) throws -> T) rethrows -> T {
		var selfBI = self.bigEndian
		return try withUnsafeMutableBytes(of:&selfBI) {
			var arv = RAW_val(mv_size:1, mv_data:$0.baseAddress!)
			return try closure(&arv)
		}
	}
	public init?(_ RAW_val:RAW_val) {
		guard RAW_val.mv_size == 1 else {
			return nil
		}
		self = UInt8(bigEndian:RAW_val.mv_data.load(as:UInt8.self))
	}
}

extension Bech32.Errors {
	/// thrown by the `NOSTR_bech32` protocol and its variants to signal that the parsed HRP does not match the HRP that is expected with the given type.
	public struct InvalidBech32HRP:Swift.Error {
		public let expectedHRP:String
		public let foundHRP:String
		public let foundData:[UInt8]
	}

	public struct InvalidElementLength:Swift.Error {
		public let body:[UInt8]
		public let body_index:Array<UInt8>.Index
		public let element_expected_length:size_t
	}
}