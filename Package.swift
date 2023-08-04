// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

// conditional dependencies based on platform.
var dependencies = [
	Package.Dependency.package(url:"https://github.com/apple/swift-argument-parser.git", from:"1.2.2"),
	Package.Dependency.package(url:"https://github.com/apple/swift-nio.git", from:"2.57.0"),
	Package.Dependency.package(url:"https://github.com/apple/swift-nio-ssl.git", from:"2.24.0"),
	Package.Dependency.package(url:"https://github.com/apple/swift-log.git", from:"1.0.0"),
	Package.Dependency.package(url:"https://github.com/tannerdsilva/QuickJSON.git", from:"1.0.2"),
	Package.Dependency.package(url:"https://github.com/tannerdsilva/rawdog.git", from:"0.0.7"),
	Package.Dependency.package(url:"https://github.com/jb55/secp256k1.swift", revision:"40b4b38b3b1c83f7088c76189a742870e0ca06a9"),
	Package.Dependency.package(url:"https://github.com/apple/swift-crypto.git", from:"2.5.0"),
	Package.Dependency.package(url:"https://github.com/apple/swift-system.git", from:"1.0.0"),
	Package.Dependency.package(url:"https://github.com/swift-server/async-http-client", from:"1.18.0")
]
var nostrTargetDeps:[PackageDescription.Target.Dependency] = [
	.product(name:"NIOSSL", package:"swift-nio-ssl"),
	.product(name:"NIO", package:"swift-nio"),
	.product(name:"NIOWebSocket", package:"swift-nio"),
	.product(name:"Logging", package:"swift-log"),
	"QuickJSON",
	.product(name:"secp256k1", package:"secp256k1.swift"),
	.product(name:"RAW", package:"rawdog"),
	.product(name:"Crypto", package:"swift-crypto"),
	.product(name:"SystemPackage", package:"swift-system"),
	.product(name:"AsyncHTTPClient", package:"async-http-client"),
	"cnostr"
]

let package = Package(
	name: "nostr-kit",
	platforms: [.macOS(.v12), .iOS(.v16), .watchOS(.v8), .tvOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(name: "nostr", targets: ["nostr"]),
		.executable(name: "nostr-cc", targets: ["nostr-cc"])
	],
	dependencies: dependencies,
	targets: [
		.target(
			name: "nostr",
			dependencies:nostrTargetDeps
		),
		.target(name:"cnostr"),
		.executableTarget(name: "nostr-cc", dependencies:[
			"nostr", 
			.product(name:"ArgumentParser", package:"swift-argument-parser")
		]),
		.testTarget(
			name: "nostr-kitTests",
			dependencies: ["nostr"]),
	]
)
