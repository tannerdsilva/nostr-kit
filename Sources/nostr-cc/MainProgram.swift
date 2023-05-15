import ArgumentParser
import Foundation
import nostr_kit

@main
struct CLI:AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "nostr-cc",
		abstract: "nostr command line client",
		subcommands: [Key.self]
	)
}

extension CLI {
	struct Key:AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "key",
			abstract: "manage keys",
			subcommands: [Key.Generate.self, Key.Info.self]
		)


		struct Generate:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "generate",
				abstract: "generate a new key"
			)

			@Argument var path:String

			func run() async throws {
				print("heres your new key")
			}
		}

		struct Info:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "info",
				abstract: "get info about a key"
			)

			@Argument var path:String

			func run() async throws {
				print("I dont know how to get info about the key at path \(path)")
			}
		}
	}
}