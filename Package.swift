// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "DebugKit",
	platforms: [
		.iOS(.v10),
		.macOS(.v10_12),
		.tvOS(.v10),
		.watchOS(.v3)
	],
	products: [
		.library(name: "DebugKit", targets: ["DebugKit"]),
	],
	targets: [
		.target(name: "DebugKit"),
		.testTarget(name: "DebugKitTests", dependencies: ["DebugKit"]),
	],
	swiftLanguageVersions: [.v5]
)
