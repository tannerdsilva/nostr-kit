// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "nostr-kit",
	platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(name: "nostr", targets: ["nostr"]),
		.executable(name: "nostr-cc", targets: ["nostr-cc"])
	],
	dependencies: [
		.package(url:"https://github.com/apple/swift-argument-parser.git", from:"1.2.2"),
		.package(url:"https://github.com/apple/swift-crypto.git", from:"2.5.0"),
		.package(url:"https://github.com/tannerdsilva/QuickLMDB.git", revision:"6454f034d5e03fbd9bb4b6b1fe1635a8471bf0e8"),
		.package(url:"https://github.com/apple/swift-nio.git", from:"2.32.1"),
		.package(url:"https://github.com/apple/swift-nio-ssl.git", from:"2.5.0"),
		.package(url:"https://github.com/swift-extras/swift-extras-base64.git", from:"0.5.0"),
		.package(url:"https://github.com/apple/swift-log.git", from:"1.4.2")
	],
	targets: [
		.target(
			name: "nostr",
			dependencies:[
				.product(name: "ExtrasBase64", package: "swift-extras-base64"),
				.product(name: "NIOSSL", package: "swift-nio-ssl"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "NIO", package: "swift-nio"),
				.product(name: "NIOWebSocket", package: "swift-nio"),
				"QuickLMDB",
				.product(name: "Logging", package: "swift-log")
			]
		),
		.executableTarget(name: "nostr-cc", dependencies:[
			"nostr", 
			.product(name:"ArgumentParser", package:"swift-argument-parser")
		]),
		.testTarget(
			name: "nostr-kitTests",
			dependencies: ["nostr"]),
	]
)
