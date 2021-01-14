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
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.1"),
	],
	targets: [
		.target(name: "DLog"),
		.target(name: "NetConsole", dependencies: [ .product(name: "ArgumentParser", package: "swift-argument-parser")]),
		.testTarget(name: "DLogTests", dependencies: ["DLog"]),
	],
	swiftLanguageVersions: [.v5]
)

