import ArgumentParser
import nostr
import QuickJSON
import class Foundation.FileManager
import struct Foundation.URL
import SystemPackage

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
				abstract: "import a keypair from input. the file will be saved in the current directory with a specified output name."
			)

			@Argument(help:"a bech32-encoded nsec string to import.")
			var nsec:String

			@Option(help:"the name of the key file to import to the current working directory")
			var name:String = "nostr-keys.nkey"

			mutating func run() async throws {
				self.name.trimExtensionIfExists(".nkey")
				let keypair = try nostr.KeyPair(seckey:SecretKey(nsec:nsec))
				let encoder = QuickJSON.Encoder()
				let encoded = try encoder.encode(keypair)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).nkey")
				let fd = try FileDescriptor.open(baseURL.path, .writeOnly, options:[.create, .truncate], permissions:[.ownerReadWrite])
				try fd.writeAll(encoded)
				try fd.close()
				print(Colors.Green("[OK] Successfully computed keypair from private key."))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				keypair.printCLIDescription(showSecretKey:true, hex:false)
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
			var name:String = "nostr-keys.nkey"

			@Flag var showNSEC:Bool = false

			mutating func run() async throws {
				self.name.trimExtensionIfExists(".nkey")
				let generateKey = try nostr.KeyPair.generateNew()
				let encoder = QuickJSON.Encoder()
				let encoded = try encoder.encode(generateKey)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).nkey")
				let fd = try FileDescriptor.open(baseURL.path, .writeOnly, options:[.create, .truncate], permissions:[.ownerReadWrite])
				try fd.writeAll(encoded)
				try fd.close()
				print(Colors.Green("[OK] Successfully generated keypair."))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				generateKey.printCLIDescription(showSecretKey:showNSEC, hex:false)
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				print(Colors.dim("Wrote keypair data to '\(baseURL.path)'"))
			}
		}

		struct Info:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "info",
				abstract: "get info about a keypair file"
			)

			@Argument(help:"the name of the key file to read from the current working directory")
			var name:String = "nostr-keys.nkey"

			@Flag var hex:Bool = false

			mutating func run() async throws {
				self.name.trimExtensionIfExists(".nkey")
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(name).nkey")
				let keyData = try nostr.KeyPair.fromJSONEncodedPath(baseURL)
				print(Colors.Green("[OK] Successfully parsed keypair from file."))
				print(Colors.dim("\(baseURL.path)"))
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
				keyData.printCLIDescription(showSecretKey:true, hex:hex)
				print(Colors.dim("- - - - - - - - - - - - - - - -"))
			}
		}
	}
}