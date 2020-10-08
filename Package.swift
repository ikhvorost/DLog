// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "DLog",
	platforms: [
		.iOS(.v10),
		.macOS(.v10_12),
		.tvOS(.v10),
		.watchOS(.v3)
	],
	products: [
		.library(
			name: "DLog",
			targets: ["DLog"]),
		.executable(
			name: "DLogNetConsole",
			targets: ["DLogNetConsole"])
	],
	targets: [
		.target(name: "DLog"),
		.target(name: "DLogNetConsole"),
		.testTarget(
			name: "DLogTests",
			dependencies: ["DLog"]),
	],
	swiftLanguageVersions: [.v5]
)

