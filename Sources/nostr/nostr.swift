// (c) tanner silva 2023. all rights reserved.

import Logging

internal struct TestData {
	internal static let keyPair = try! KeyPair(seckey:SecretKey(nsec:"nsec1s23j6z0x4w2y35c5zkf6le539sdmkmw4r7mm9jj22gnltrllqxzqjnh2wm"))
}

internal func makeDefaultLogger(label:String, logLevel:Logger.Level) -> Logger {
	var newLogger = Logger(label:label)
	newLogger.logLevel = logLevel
	return newLogger
}