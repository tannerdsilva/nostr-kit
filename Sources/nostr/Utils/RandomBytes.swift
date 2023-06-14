#if os(Linux)
	import Glibc
	import SystemPackage
#elseif os(macOS)
	import Darwin.C
	import SystemPackage
#else
	import Foundation
#endif

internal struct RandomBytes {
	/// generate random bytes of a given size
	/// - parameter size: the number of bytes to generate
	/// - returns: an array of random bytes
	#if os(Linux) || os(macOS)
	internal static func generate(size:size_t) throws -> [UInt8] {
		let randomBuffer = malloc(size);
		defer {
			free(randomBuffer)
		}
		let randomFD = try FileDescriptor.open("/dev/urandom", .readOnly)
		defer {
			close(randomFD.rawValue)
		}
		var totalRead = 0
		repeat {
			totalRead += try randomFD.read(into:UnsafeMutableRawBufferPointer(start:randomBuffer!.advanced(by:totalRead), count:size))
		} while totalRead < size
		return Array(UnsafeBufferPointer(start:randomBuffer!.assumingMemoryBound(to:UInt8.self), count:size))
	}
	#else
	internal static func generate(size:size_t) throws -> [UInt8] {
		var randomBuffer = [UInt8](repeating: 0, count: size)
        let result = SecRandomCopyBytes(kSecRandomDefault, size, &randomBuffer)

        guard result == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
        }
        
        return randomBuffer
	}
	#endif
}