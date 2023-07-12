// (c) tanner silva 2023. all rights reserved.

import cnostr
import SystemPackage
internal struct RandomBytes {
	/// generate random bytes of a given size
	/// - parameter size: the number of bytes to generate
	/// - returns: an array of random bytes
	internal static func generate(size:size_t) throws -> [UInt8] {
		let randomBuffer = malloc(size);
		defer {
			free(randomBuffer)
		}
		let randomFD = try FileDescriptor.open("/dev/random", .readOnly)
		defer {
			close(randomFD.rawValue)
		}
		var totalRead = 0
		repeat {
			totalRead += try randomFD.read(into:UnsafeMutableRawBufferPointer(start:randomBuffer!.advanced(by:totalRead), count:size))
		} while totalRead < size
		return Array(UnsafeBufferPointer(start:randomBuffer!.assumingMemoryBound(to:UInt8.self), count:size))
	}
}