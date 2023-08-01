import AsyncHTTPClient
import QuickJSON

/// represents a parsed NIP05 name string (username@host)
public struct NIP05 {

	#if DEBUG
	static let logger = makeDefaultLogger(label:"nip05", logLevel:.debug)
	#endif
	
	/// errors that may occur when parsing a nip05 string
	public enum Error:Swift.Error {
		case invalidURL
		case invalidResponse
	}

	/// the public key of a user
	public struct Response:Codable {
		public enum CodingKeys:String, CodingKey {
			case names = "names"
			case relays = "relays"
		}
		let names:[String:PublicKey]
		let relays:[PublicKey:[String]]

		public init(names:[String:PublicKey], relays:[PublicKey:[String]]) {
			self.names = names
			self.relays = relays
		}

		public init(from decoder:Swift.Decoder) throws {
			let container = try decoder.container(keyedBy:CodingKeys.self)
			self.names = try container.decode([String:PublicKey].self, forKey:.names)
			let nestedKeyed = try container.nestedContainer(keyedBy:PublicKey.self, forKey:.relays)
			var relays:[PublicKey:[String]] = [:]
			for key in nestedKeyed.allKeys {
				let relay = try nestedKeyed.decode([String].self, forKey:key)
				relays[key] = relay
			}
			self.relays = relays
		}

		public func encode(to encoder:Swift.Encoder) throws {
			var container = encoder.container(keyedBy:CodingKeys.self)
			try container.encode(self.names, forKey:.names)
			var nestedKeyed = container.nestedContainer(keyedBy:PublicKey.self, forKey:.relays)
			for (publicKey, relays) in self.relays {
				try nestedKeyed.encode([publicKey.hexEncodedString(), relays[0]], forKey:publicKey)
			}
		}
	}

	/// the local of the NIP05 name (the part before the @ symbol)
	let local:String

	/// the domain of the NIP05 name (the part after the @ symbol)
	let domain:String
	
	/// initialize with a local and domain name
	public init(local:String, domain:String) {
		self.local = local
		self.domain = domain
	}

	/// the full NIP05 name
	public init?(_ nip05:String) {
		let parts = nip05.split(separator:"@")
		guard parts.count == 2 else {
			return nil
		}
		// pick the two main components of a NIP05
		let nameCandidate = String(parts[0])
		let domainCandidate = String(parts[1])

		// validate that they look good
		guard nameCandidate.count > 0, domainCandidate.count > 0 else {
			return nil
		}
		let splitDomain = domainCandidate.split(separator:".")
		guard splitDomain.count > 1 else {
			return nil
		}
		for subdomain in splitDomain {
			guard subdomain.count > 0 else {
				return nil
			}
		}
		self.local = nameCandidate
		self.domain = domainCandidate
	}

	/// retrieve the public key of a user
	func verify() async throws -> Response {
		let newClient = HTTPClient(eventLoopGroupProvider: .createNew)
		defer {
			try? newClient.syncShutdown()
		}

		// build URL components out of the base url
		let buildURL = "https://\(self.domain)/.well-known/nostr.json?name=\(self.local)"
		let request = try HTTPClient.Request(url:buildURL, method:.GET)

		// send the request
		let response = try await newClient.execute(request: request).get()
		guard response.status == .ok, var responseBody = response.body, let responseBytesRead = responseBody.readBytes(length:responseBody.readableBytes) else {
			throw Error.invalidResponse
		}

		// decode the response
		let decodedResponse = try QuickJSON.decode(Response.self, from:responseBytesRead, size:responseBytesRead.count)
		return decodedResponse
	}
}
