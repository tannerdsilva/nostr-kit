import Logging

internal func makeDefaultLogger(label:String, logLevel:Logger.Level) -> Logger {
	var newLogger = Logger(label:label)
	newLogger.logLevel = logLevel
	return newLogger
}