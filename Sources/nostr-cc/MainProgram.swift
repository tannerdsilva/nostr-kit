import ArgumentParser
import nostr
import QuickJSON
import SystemPackage
import Foundation
import RAW
import NIO

@main
struct CLI:AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "nostr-cc",
		abstract: "nostr command line client",
		subcommands: [KeyPair.self, Relay.self]
	)
}

extension CLI {
	struct Relay:AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "relay",
			abstract: "manage relays",
			subcommands: [Relay.Connect.self]
		)

		struct Connect:ParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "connect",
				abstract: "connect to a relay"
			)

			@Argument(help:"the url of the relay to connect to")
			var url:String = "wss://relay.damus.io"

			@Option(help:"your nostr key to use for this task")
			var myKey:String = "nostr-keys"

			func run() throws {
				let mainEventLoop = MultiThreadedEventLoopGroup(numberOfThreads:1)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(myKey).json")
				let readKey = try nostr.KeyPair.fromJSONEncodedPath(baseURL)
				var buildConf = nostr.Relay.Client.Configuration(authenticationKey:readKey)
				let relayConn = try nostr.Relay.connect(url:nostr.Relay.URL(url), configuration: buildConf, on:mainEventLoop.next()).wait()
				var buildFilter = nostr.Filter(authors:[readKey.pubkey])
				sleep(512)
				
				// var config = nostr.Relay.Configuration(authenticationKey:
				// let relay = try nostr.Relay.connect(url:try nostr.Relay.URL(url))
			}
		}

		struct MyProfile:ParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "my-profile",
				abstract: "query a relay for your profile."
			)

			@Argument
			var url:String = "wss://relay.damus.io"

			@Option(help:"the name of the key file to use for authentication")
			var key:String = "nostr-keys"
		}
	}
}

extension CLI {
	struct KeyPair:AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "keypair",
			abstract: "manage keypair",
			subcommands: [KeyPair.Generate.self, KeyPair.Info.self, KeyPair.Import.self]
		)

		struct Import:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "import",
				abstract: "import a keypair from input"
			)

			@Argument(help:"a bech32-encoded nsec private key to import")
			var nsec:String

			@Option(help:"the name of the key file to import to the current working directory")
			var name:String = "nostr-keys"

			func run() async throws {
				let keypair = try nostr.KeyPair(seckey:nostr.Key(nsec:nsec))
				let encoder = QuickJSON.Encoder()
				let encoded = try encoder.encode(keypair)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).json")
				let fd = try FileDescriptor.open(baseURL.path, .writeOnly, options:[.create, .truncate], permissions:[.ownerReadWrite])
				try fd.writeAll(encoded)
				try fd.close()
				print(Colors.Green("[OK] Successfully computed keypair from private key."))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				keypair.printCLIDescription(showSecretKey:true)
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				print(Colors.dim("Wrote keypair data to '\(nsec)'"))
			}
		}

		struct Generate:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "generate",
				abstract: "generate a new key of a specified name. the key will be exported to a file in the current working directory."
			)

			@Argument(help:"the name of the key file to generate at the current working directory")
			var name:String = "nostr-keys"

			@Flag var showNSEC:Bool = false

			func run() async throws {
				let generateKey = try nostr.KeyPair.generateNew()
				let encoder = QuickJSON.Encoder()
				let encoded = try encoder.encode(generateKey)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).json")
				let fd = try FileDescriptor.open(baseURL.path, .writeOnly, options:[.create, .truncate], permissions:[.ownerReadWrite])
				try fd.writeAll(encoded)
				try fd.close()
				print(Colors.Green("[OK] Successfully generated keypair."))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				generateKey.printCLIDescription(showSecretKey:showNSEC)
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				print(Colors.dim("Wrote keypair data to '\(baseURL.path)'"))
			}
		}

		struct Info:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "info",
				abstract: "get info about a keypair json file"
			)

			@Argument(help:"the name of the key file to read from the current working directory")
			var name:String

			func run() async throws {
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).json")
				let keyData = try nostr.KeyPair.fromJSONEncodedPath(baseURL)
				print(Colors.Green("[OK] Successfully parsed keypair from file."))
				print(Colors.dim("\(baseURL.path)"))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				keyData.printCLIDescription(showSecretKey:true)
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
			}
		}
	}
}