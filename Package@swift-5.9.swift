// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DLog",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .visionOS(.v1),
    .watchOS(.v6)
  ],
  products: [
    .library(name: "DLog", targets: ["DLog"]),
    .library(name: "DLogObjC", targets: ["DLogObjC"]),
    .executable(name: "NetConsole", targets: ["NetConsole"])
  ],
  targets: [
    .target(name: "DLog"),
    .target(name: "DLogObjC", dependencies: ["DLog"]),
    .executableTarget(name: "NetConsole"),
    .testTarget(name: "DLogTests", dependencies: ["DLog"]),
    .testTarget(name: "DLogTestsObjC", dependencies: ["DLogObjC"])
  ],
  swiftLanguageVersions: [.v5]
)
