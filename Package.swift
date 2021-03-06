// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "DLog",
	platforms: [
		.iOS(.v12),
		.macOS(.v10_14),
		.tvOS(.v12),
		.watchOS(.v5)
	],
	products: [
		.library(name: "DLog", targets: ["DLog"]),
		.executable(name: "NetConsole", targets: ["NetConsole"])
	],
	targets: [
		.target(name: "DLog"),
		.target(name: "NetConsole"),
		.testTarget(name: "DLogTests", dependencies: ["DLog"]),
	],
	swiftLanguageVersions: [.v5]
)

