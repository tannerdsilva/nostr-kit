// (c) tanner silva 2023. all rights reserved.

import NIOCore
import NIOHTTP1

// I dont love what is happening in this file. I feel like these errors need to go somewhere else

/// default HTTP error. provides an HTTP status and a message is so desired
public struct HTTPError:Swift.Error, Sendable {
	/// status code for the error
	public let status:HTTPResponseStatus
	/// any addiitional headers required
	public let headers:HTTPHeaders
	/// error payload, assumed to be a string
	public let body:String?

	/// initialize HTTPError with a given response status
	public init(_ status:HTTPResponseStatus) {
		self.status = status
		self.headers = [:]
		self.body = nil
	}

	/// initialize HTTPError with a given HTTP response status and message
	public init(_ status:HTTPResponseStatus, message:String) {
		self.status = status
		self.headers = ["content-type": "text/plain; charset=utf-8"]
		self.body = message
	}

	/// get body of error as ByteBuffer
	public func body(allocator: ByteBufferAllocator) -> ByteBuffer? {
		return self.body.map { allocator.buffer(string: $0) }
	}
}

extension HTTPError:CustomStringConvertible {
	/// description of error for logging
	public var description: String {
		let status = self.status.reasonPhrase
		return "HTTPError: \(status)\(self.body.map { ", \($0)" } ?? "")"
	}
}


public enum Error:Swift.Error {
	/// failed to upgrade the HTTP connection to WebSocket protocol
	case websocketUpgradeFailure

	case invalidURL

	case invalidPublicKey
}

