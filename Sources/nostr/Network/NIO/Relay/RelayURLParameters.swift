// this code was taken from the hummingbird server framework, and is subject to the apache 2.0 license

/// Provides Dictionary like indexing, but uses a flat array of key
/// value pairs, plus an array of hash keys for lookup for storage.
///
/// Useful for dictionary lookup on small collection that don't need
/// a tree lookup to optimise indexing.
///
/// The FlatDictionary also allows for key clashes. Standard lookup
/// functions will always return the first key found, but if you
/// iterate through the key,value pairs you can access all values
/// for a key
public struct FlatDictionary<Key: Hashable, Value>: Collection, ExpressibleByDictionaryLiteral {
    public typealias Element = (key: Key, value: Value)
    public typealias Index = Array<Element>.Index

    // MARK: Collection requirements

    /// The position of the first element
    public var startIndex: Index { self.elements.startIndex }
    /// The position of the element just after the last element
    public var endIndex: Index { self.elements.endIndex }
    /// Access element at specific position
    public subscript(_ index: Index) -> Element { return self.elements[index] }
    /// Returns the index immediately after the given index
    public func index(after index: Index) -> Index { self.elements.index(after: index) }

    /// Create a new FlatDictionary
    public init() {
        self.elements = []
        self.hashKeys = []
    }

    /// Create a new FlatDictionary initialized with a dictionary literal
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.elements = elements.map { (key: $0.0, value: $0.1) }
        self.hashKeys = elements.map {
            Self.hashKey($0.0)
        }
    }

    /// Create a new FlatDictionary from an array of key value pairs
    public init(_ values: [Element]) {
        self.elements = values
        self.hashKeys = values.map {
            Self.hashKey($0.key)
        }
    }

    /// Access the value associated with a given key for reading and writing
    ///
    /// Because FlatDictionary allows for key clashes this function will
    /// return the first entry in the array with the associated key
    public subscript(_ key: Key) -> Value? {
        get {
            let hashKey = Self.hashKey(key)
            if let index = hashKeys.firstIndex(of: hashKey) {
                return self.elements[index].value
            } else {
                return nil
            }
        }
        set {
            let hashKey = Self.hashKey(key)
            if let index = hashKeys.firstIndex(of: hashKey) {
                if let newValue = newValue {
                    self.elements[index].value = newValue
                } else {
                    self.elements.remove(at: index)
                    self.hashKeys.remove(at: index)
                }
            } else if let newValue = newValue {
                self.elements.append((key: key, value: newValue))
                self.hashKeys.append(hashKey)
            }
        }
    }

    ///  Return if dictionary has this value
    /// - Parameter key:
    public func has(_ key: Key) -> Bool {
        let hashKey = Self.hashKey(key)
        return self.hashKeys.firstIndex(of: hashKey) != nil
    }

    /// Return all the values, associated with a given key
    public func getAll(for key: Key) -> [Value] {
        var values: [Value] = []
        let hashKey = Self.hashKey(key)

        for hashIndex in 0..<self.hashKeys.count {
            if self.hashKeys[hashIndex] == hashKey {
                values.append(self.elements[hashIndex].value)
            }
        }
        return values
    }

    /// Append a new key value pair to the list of key value pairs
    public mutating func append(key: Key, value: Value) {
        let hashKey = Self.hashKey(key)
        self.elements.append((key: key, value: value))
        self.hashKeys.append(hashKey)
    }

    private static func hashKey(_ key: Key) -> Int {
        var hasher = Hasher()
        hasher.combine(key)
        return hasher.finalize()
    }

    private var elements: [Element]
    private var hashKeys: [Int]
}

// FlatDictionary is Sendable when Key and Value are Sendable
extension FlatDictionary: Sendable where Key: Sendable, Value: Sendable {}

/// Store for parameters key, value pairs extracted from URI
extension Relay.URL {
	internal struct Parameters: Sendable {
		public typealias Collection = FlatDictionary<Substring, Substring>
		internal var parameters: Collection

		static let recursiveCaptureKey: Substring = ":**:"

		init() {
			self.parameters = .init()
		}

		init(_ values: Collection) {
			self.parameters = values
		}

		/// Return if parameter exists
		/// - Parameter s: parameter id
		public func has(_ s: Substring) -> Bool {
			return self.parameters.has(s)
		}

		/// Return parameter with specified id
		/// - Parameter s: parameter id
		public func get(_ s: String) -> String? {
			return self.parameters[s[...]].map { String($0) }
		}

		/// Return parameter with specified id as a certain type
		/// - Parameters:
		///   - s: parameter id
		///   - as: type we want returned
		public func get<T: LosslessStringConvertible>(_ s: String, as: T.Type) -> T? {
			return self.parameters[s[...]].map { T(String($0)) } ?? nil
		}

		///  Return path elements caught by recursive capture
		public func getCatchAll() -> [Substring] {
			return self.parameters[Self.recursiveCaptureKey].map { $0.split(separator: "/", omittingEmptySubsequences: true) } ?? []
		}

		/// Return parameter with specified id
		/// - Parameter s: parameter id
		public func require(_ s: String) throws -> String {
			guard let param = self.parameters[s[...]].map({ String($0) }) else {
				throw HBHTTPError(.badRequest)
			}
			return param
		}

		/// Return parameter with specified id as a certain type
		/// - Parameters:
		///   - s: parameter id
		///   - as: type we want returned
		public func require<T: LosslessStringConvertible>(_ s: String, as: T.Type) throws -> T {
			guard let param = self.parameters[s[...]],
				let result = T(String(param))
			else {
				throw HBHTTPError(.badRequest)
			}
			return result
		}

		/// Return parameter with specified id
		/// - Parameter s: parameter id
		public func getAll(_ s: String) -> [String] {
			return self.parameters.getAll(for: s[...]).map { String($0) }
		}

		/// Return parameter with specified id as a certain type
		/// - Parameters:
		///   - s: parameter id
		///   - as: type we want returned
		public func getAll<T: LosslessStringConvertible>(_ s: String, as: T.Type) -> [T] {
			return self.parameters.getAll(for: s[...]).compactMap { T(String($0)) }
		}

		/// Return parameter with specified id as a certain type
		/// - Parameters:
		///   - s: parameter id
		///   - as: type we want returned
		public func requireAll<T: LosslessStringConvertible>(_ s: String, as: T.Type) throws -> [T] {
			return try self.parameters.getAll(for: s[...]).compactMap {
				guard let result = T(String($0)) else {
					throw HBHTTPError(.badRequest)
				}
				return result
			}
		}

		/// Set parameter
		/// - Parameters:
		///   - s: parameter id
		///   - value: parameter value
		mutating func set(_ s: Substring, value: Substring) {
			self.parameters[s] = value
		}

		/// Set path components caught by recursive capture
		/// - Parameters:
		///   - value: parameter value
		mutating func setCatchAll(_ value: Substring) {
			guard !self.parameters.has(Self.recursiveCaptureKey) else { return }
			self.parameters[Self.recursiveCaptureKey] = value
		}

		public subscript(_ s: String) -> String? {
			return self.parameters[s[...]].map { String($0) }
		}

		public subscript(_ s: Substring) -> String? {
			return self.parameters[s].map { String($0) }
		}
	}
}

extension Relay.URL.Parameters: Collection {
    public typealias Index = Collection.Index
    public var startIndex: Index { self.parameters.startIndex }
    public var endIndex: Index { self.parameters.endIndex }
    public subscript(_ index: Index) -> Collection.Element { return self.parameters[index] }
    public func index(after index: Index) -> Index { self.parameters.index(after: index) }
}

extension Relay.URL.Parameters: CustomStringConvertible {
    public var description: String {
        String(describing: self.parameters)
    }
}
