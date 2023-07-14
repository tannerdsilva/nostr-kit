import ArgumentParser
import nostr
import Foundation
import QuickJSON

@main
struct CLI:AsyncParsableCommand {
	/// the logger for the CLI.
	static let logger = makeDefaultLogger(label:"cc", logLevel:.debug)

	static let configuration = CommandConfiguration(
		commandName: "nostr-cc",
		abstract: "nostr commandline-client.",
		subcommands: [KeyPair.self, Relay.self]
	)
}