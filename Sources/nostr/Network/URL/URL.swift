// (c) tanner silva 2023. all rights reserved.

/// a url that represents a relay endpoint
public struct URL:Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
	
	/// The scheme for the URL
	public struct Scheme:Equatable {
		public let rawValue: String
		public init(rawValue: String) {
			self.rawValue = rawValue
		}

		/// Insecure websocket protocol
		public static var ws: Self { return .init(rawValue: "ws") }

		/// Secure websocket protocol
		public static var wss: Self { return .init(rawValue: "wss") }

		public static var https: Self { return .init(rawValue: "https") }
	}

	/// The string representation of the URL
	public let string:String

	/// URL scheme
	public var scheme:Scheme? { return self._scheme.map { Scheme.init(rawValue: $0.string) } }
	/// URL host
	public var host:String? { return self._host.map({ $0.string }) }
	/// URL port
	public var port:Int? { return self._port.map { Int($0.string) } ?? nil }
	/// URL path
	public var path:String { return self._path.map( { $0.string }) ?? "/" }
	/// URL query
	public var query:String? { return self._query.map { String($0.string) }}
	/// URL query parameter map
	public var queryParameters:URL.Parameters { return .init(fromQuery: self._query) }

	private let _scheme:URL.Parser?
	private let _host:URL.Parser?
	private let _port:URL.Parser?
	private let _path:URL.Parser?
	private let _query:URL.Parser?

	public var description:String { self.string }

	/// Initialize `HBURL` from `String`
	/// - Parameter string: input string
	public init(_ string:String) {
		enum ParsingState {
			case readingScheme
			case readingHost
			case readingPort
			case readingPath
			case readingQuery
			case finished
		}
		var scheme:URL.Parser?
		var host:URL.Parser?
		var port:URL.Parser?
		var path:URL.Parser?
		var query:URL.Parser?
		var state:ParsingState = .readingScheme
		if string.first == "/" {
			state = .readingPath
		}

		var parser = Parser(string)
		while state != .finished {
			if parser.reachedEnd() { break }
			switch state {
			case .readingScheme:
				// search for "://" to find scheme and host
				scheme = try? parser.read(untilString: "://", skipToEnd: true)
				if scheme != nil {
					state = .readingHost
				} else {
					state = .readingPath
				}

			case .readingHost:
				let h = try! parser.read(until: Self.hostEndSet, throwOnOverflow: false)
				if h.count != 0 {
					host = h
				}
				if parser.current() == ":" {
					state = .readingPort
				} else if parser.current() == "?" {
					state = .readingQuery
				} else {
					state = .readingPath
				}

			case .readingPort:
				parser.unsafeAdvance()
				port = try! parser.read(until: Self.portEndSet, throwOnOverflow: false)
				state = .readingPath

			case .readingPath:
				path = try! parser.read(until: "?", throwOnOverflow: false)
				state = .readingQuery

			case .readingQuery:
				parser.unsafeAdvance()
				query = try! parser.read(until: "#", throwOnOverflow: false)
				state = .finished

			case .finished:
				break
			}
		}

		self.string = string
		self._scheme = scheme
		self._host = host
		self._port = port
		self._path = path
		self._query = query
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	private static let hostEndSet: Set<Unicode.Scalar> = Set(":/?")
	private static let portEndSet: Set<Unicode.Scalar> = Set("/?")
}

extension URL.Parameters {
	/// Initialize parameters from parser struct
	/// - Parameter query: parser holding query strings
	internal init(fromQuery query: URL.Parser?) {
		guard var query = query else {
			self.parameters = .init()
			return
		}
		let queries: [URL.Parser] = query.split(separator: "&")
		let queryKeyValues = queries.map { query -> (key: Substring, value: Substring) in
			do {
				var query = query
				let key = try query.read(until: "=")
				query.unsafeAdvance()
				if query.reachedEnd() {
					return (key: key.string[...], value: "")
				} else {
					let value = query.readUntilTheEnd()
					return (key: key.string[...], value: value.percentDecode().map { $0[...] } ?? value.string[...])
				}
			} catch {
				return (key: query.string[...], value: "")
			}
		}
		self.parameters = .init(queryKeyValues)
	}
}