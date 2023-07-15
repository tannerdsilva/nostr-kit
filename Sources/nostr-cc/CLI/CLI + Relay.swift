import ArgumentParser
import NIO
import nostr
import struct Foundation.URL
import class Foundation.FileManager
import QuickJSON

extension CLI {
	struct Relay:AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "relay",
			abstract: "take network action on relays.",
			subcommands:[Relay.Post.self]
		)

		struct Connect:ParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "connect",
				abstract: "connect to a relay."
			)

			@Argument(help:"the url of the relay to connect to.")
			var url:String

			@Argument(help:"your nostr key to use for this task.")
			var myKey:String = "nostr-keys.nkey"

			mutating func run() throws {
				myKey.trimExtensionIfExists(".nkey")
				let mainEventLoop = MultiThreadedEventLoopGroup(numberOfThreads:1)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(myKey).nkey")
				let readKey = try nostr.KeyPair.fromJSONEncodedPath(baseURL)
				let buildConf = nostr.Relay.Client.Configuration(authenticationKey:readKey)
				let relayConn = try nostr.Relay.connect(url:nostr.URL(url), configuration: buildConf, on:mainEventLoop.next()).wait()

				sleep(512)
				
				// var config = nostr.Relay.Configuration(authenticationKey:
				// let relay = try nostr.Relay.connect(url:try nostr.Relay.URL(url))
			}
		}

		struct Post:AsyncParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "post",
				abstract: "post a signed text note event (kind 1) a relay.",
				discussion:"the process will wait for the event to be published before exiting."
			)

			@Argument(help:"the url of the relay to connect to")
			var url:String

			@Argument(help:"the message you would like to post")
			var myMessage:String

			@Argument(help:"the file name to use for your key.")
			var myKey:String = "nostr-keys.nkey"

			mutating func run() async throws {
				self.myKey.trimExtensionIfExists(".nkey")
				let mainEventLoop = MultiThreadedEventLoopGroup(numberOfThreads:1)
				let baseURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("\(myKey).nkey")
				let readKey = try nostr.KeyPair.fromJSONEncodedPath(baseURL)
				let buildConf = nostr.Relay.Client.Configuration(authenticationKey:readKey)
				let relayConn = try await nostr.Relay.connect(url:nostr.URL(url), configuration: buildConf, on:mainEventLoop.next()).get()
				
				var unsignedEvent = nostr.Event.Unsigned(kind:nostr.Event.Kind.text_note)
				unsignedEvent.content = myMessage
				let newEvent = try unsignedEvent.sign(type:nostr.Event.Signed.self, as:readKey)
				CLI.logger.info("posting event: \(newEvent.uid.description.prefix(8))")
				let result = try await relayConn.write(event:newEvent).get()
				result.promise.futureResult.whenComplete { getResult in
					switch getResult {
						case .success(let event):
							CLI.logger.info("successfully posted event: \(newEvent.uid.description.prefix(8))")
						case .failure(let error):
							print("event failed: \(error)")
					}
				}
				_ = try await result.promise.futureResult.get()
				// var config = nostr.Relay.Configuration(authenticationKey:
				// let relay = try nostr.Relay.connect(url:try nostr.Relay.URL(url))
			}
		}
	}
}
