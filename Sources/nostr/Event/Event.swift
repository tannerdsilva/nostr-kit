import typealias QuickLMDB.MDB_convertible
import protocol QuickLMDB.MDB_comparable
import struct QuickLMDB.MDB_val

// @usableFromInline struct Event {
// 	private enum CodingKeys:String, CodingKey {
// 		case uid = "id"
// 		case sig = "sig"
// 		case tags = "tags"
// 		case boosted_by = "boosted_by"
// 		case pubkey = "pubkey"
// 		case created = "created_at"
// 		case kind = "kind"
// 		case content = "content"
// 	}
// }

// struct Tag:Codable {
// 	enum Error:Swift.Error {
// 		case unknownTagKind
// 	}
	
// 	static func fromPublicKey(_ key:nostr.Key) -> Tag {
// 		return Self(["p", key.description])
// 	}
	
// 	static let logger = Topaz.makeDefaultLogger(label:"nostr.Event.Tag")

// 	enum Kind:Codable, LosslessStringConvertible, Equatable {
// 		/// a tag that references another nostr event
// 		case event
// 		/// a tag that references a user
// 		case pubkey

// 		/// any kind of tag that is not supported in this software
// 		case unknown(String)
// 	}

// 	let kind:Kind
// 	let info:[String]
	
// 	var count:Int {
// 		return info.count + 1
// 	}
	
// 	init(_ array:[String]) {
// 		let makeKind = Kind(array[0])
// 		self.kind = makeKind
// 		self.info = Array(array[array.startIndex.advanced(by: 1)..<array.count])
// 	}

// 	init(from decoder: Decoder) throws {
// 		do {
// 			var container = try decoder.unkeyedContainer()
// 			self.kind = try container.decode(Kind.self)
// 			var otherValues:[String] = []
// 			while !container.isAtEnd {
// 				otherValues.append(try container.decode(String.self))
// 			}
// 			self.info = otherValues
// 		} catch let error {
// 			Self.logger.debug("error decoding tag.", metadata:["error": "\(error)"])
// 			throw error
// 		}
// 	}
// 	func encode(to encoder: Encoder) throws {
// 		do {
// 			var container = encoder.unkeyedContainer()
// 			try container.encode(kind)
// 			for curVal in info {
// 				try container.encode(curVal)
// 			}
// 		} catch let error {
// 			Self.logger.debug("error encoding tag.", metadata:["error": "\(error)"])
// 			throw error
// 		}
// 	}
	
// 	subscript(_ index:Int) -> String {
// 		get {
// 			if index == 0 {
// 				return kind.description
// 			} else {
// 				return info[index-1]
// 			}
// 		}
// 	}
	
// 	func toArray() -> [String] {
// 		var buildArray = [kind.description]
// 		buildArray.append(contentsOf:info)
// 		return buildArray
// 	}
	
// 	func toReference() -> ReferenceID {
// 		var relay_id:String? = nil
// 		if info.count > 2 {
// 			relay_id = info[2]
// 		}

// 		return ReferenceID(ref_id:info[1], relay_id:relay_id, key:self.kind.description)
// 	}
// }

// // Defines Event Kinds
// extension nostr.Event {
// 	@frozen @usableFromInline enum Kind:Int, Equatable, MDB_convertible, Codable {
// 		case metadata = 0
// 		case text_note = 1
// 		case recommended_relay = 2
// 		case contacts = 3
// 		case dm = 4
// 		case delete = 5
// 		case boost = 6
// 		case like = 7
// 		case channel_create = 8
// 		case channel_meta = 9
// 		case chat = 42
// 		case list = 40000 // (?)
// 		case zap = 9735
// 		case zap_request = 9734
// 		case private_zap = 9733 // I think?
// 		case list_mute = 10000
// 		case list_pin = 10001
// 		case list_categorized = 30000
// 		case list_categorized_bookmarks = 30001
// 	}
// }

// extension Event.UID {
// 	@frozen @usableFromInline struct UID:MDB_convertible, MDB_comparable, Hashable, Equatable, Comparable, LosslessStringConvertible, Codable {
// 		enum Error:Swift.Error {
// 			case invalidStringLength(String)
// 		}

// 		static func nullUID() -> Self {
// 			return Self()
// 		}
		
// 		static func generatedFrom(event:nostr.Event) throws -> Self {
// 			let commitment = try event.commitment()
// 			let hashed = sha256(commitment)
// 			return Self(hashed)
// 		}

// 		// Lexigraphical sorting here
// 		@usableFromInline static let mdbCompareFunction:@convention(c) (UnsafePointer<MDB_val>?, UnsafePointer<MDB_val>?) -> Int32 = { a, b in
// 			let aData = a!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
// 			let bData = b!.pointee.mv_data!.assumingMemoryBound(to: Self.self)
			
// 			let minLength = min(a!.pointee.mv_size, b!.pointee.mv_size)
// 			let comparisonResult = memcmp(aData, bData, minLength)

// 			if comparisonResult != 0 {
// 				return Int32(comparisonResult)
// 			} else {
// 				// If the common prefix is the same, compare their lengths.
// 				return Int32(a!.pointee.mv_size) - Int32(b!.pointee.mv_size)
// 			}
// 		}

// 		@usableFromInline static func == (lhs: nostr.Event.UID, rhs: nostr.Event.UID) -> Bool {
// 			return lhs.asMDB_val({ lhsVal in
// 				return rhs.asMDB_val({ rhsVal in
// 					return Self.mdbCompareFunction(&lhsVal, &rhsVal) == 0
// 				})
// 			})
// 		}
		
// 		@usableFromInline static func < (lhs: nostr.Event.UID, rhs: nostr.Event.UID) -> Bool {
// 			return lhs.asMDB_val({ lhsVal in
// 				return rhs.asMDB_val({ rhsVal in
// 					return Self.mdbCompareFunction(&lhsVal, &rhsVal) < 0
// 				})
// 			})
// 		}

// 		var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		
// 		@usableFromInline var description: String {
// 			get {
// 				hex_encode(self.exportData())
// 			}
// 		}
		
// 		@usableFromInline internal init?(_ description:String) {
// 			guard let asBytes = hex_decode(description) else {
// 				return nil
// 			}
			
// 			guard asBytes.count == MemoryLayout<Self>.size else {
// 				return nil
// 			}
// 			self = Self.init(Data(asBytes))
// 		}

// 		/// Initialize from Data containing SHA256 hash
// 		internal init(_ hashData: Data) {
// 			hashData.withUnsafeBytes({ byteBuffer in
// 				memcpy(&bytes, byteBuffer, MemoryLayout<Self>.size)
// 			})
// 		}

// 		/// Null Initializer
// 		fileprivate init() {}

// 		// MDB_convertible
// 		@usableFromInline internal init?(_ value: MDB_val) {
// 			guard value.mv_size == MemoryLayout<Self>.size else {
// 				return nil
// 			}
// 			_ = memcpy(&bytes, value.mv_data, MemoryLayout<Self>.size)
// 		}
// 		public func asMDB_val<R>(_ valFunc: (inout MDB_val) throws -> R) rethrows -> R {
// 			return try withUnsafePointer(to: bytes, { unsafePointer in
// 				var val = MDB_val(mv_size: MemoryLayout<Self>.size, mv_data: UnsafeMutableRawPointer(mutating: unsafePointer))
// 				return try valFunc(&val)
// 			})
// 		}
		
// 		// Hashable
// 		public func hash(into hasher:inout Hasher) {
// 			asMDB_val({ hashVal in
// 				hasher.combine(hashVal)
// 			})
// 		}
		
// 		/// Export the hash as a Data struct
// 		public func exportData() -> Data {
// 			withUnsafePointer(to:bytes) { byteBuff in
// 				return Data(bytes:byteBuff, count:MemoryLayout<Self>.size)
// 			}
// 		}
		
// 		/// Codable
// 		@usableFromInline init(from decoder:Decoder) throws {
// 			let container = try decoder.singleValueContainer()
// 			let asString = try container.decode(String.self)
// 			guard let makeSelf = Self(asString) else {
// 				throw Error.invalidStringLength(asString)
// 			}
// 			self = makeSelf
// 		}
// 		@usableFromInline  func encode(to encoder: Encoder) throws {
// 			var container = encoder.singleValueContainer()
// 			try container.encode(self.description)
// 		}
// 	}
// }

// extension nostr.Event.Kind {
// 	@usableFromInline init?(_ value:MDB_val) {
// 		guard MemoryLayout<Int>.size == value.mv_size else {
// 			return nil
// 		}
// 		guard let asSelf = Self(rawValue:value.mv_data.bindMemory(to:Int.self, capacity:1).pointee) else {
// 			return nil
// 		}
// 		self = asSelf
// 	}
// 	@usableFromInline func asMDB_val<R>(_ valFunc:(inout MDB_val) throws -> R) rethrows -> R {
// 		return try withUnsafePointer(to:self.rawValue) { rawVal in
// 			var val = MDB_val(mv_size:MemoryLayout<Int>.size, mv_data:UnsafeMutableRawPointer(mutating: rawVal))
// 			return try valFunc(&val)
// 		}
// 	}
// }