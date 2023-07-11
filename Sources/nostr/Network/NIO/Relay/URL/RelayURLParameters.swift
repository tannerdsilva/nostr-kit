// (c) tanner silva 2023. all rights reserved.

/// Store for parameters key, value pairs extracted from URI
extension Relay.URL {
	public struct Parameters: Sendable {
		public typealias Collection = FlatDictionary<Substring, Substring>
		
		internal var parameters:Collection

		private static let recursiveCaptureKey: Substring = ":**:"

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
				throw HTTPError(.badRequest)
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
				throw HTTPError(.badRequest)
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
					throw HTTPError(.badRequest)
				}
				return result
			}
		}

		/// Set parameter
		/// - Parameters:
		///   - s: parameter id
		///   - value: parameter value
		public mutating func set(_ s: Substring, value: Substring) {
			self.parameters[s] = value
		}

		/// Set path components caught by recursive capture
		/// - Parameters:
		///   - value: parameter value
		public mutating func setCatchAll(_ value: Substring) {
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
