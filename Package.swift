// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Clickstream",
    platforms: [.macOS(.v10_12),
                .iOS(.v11),
                .tvOS(.v10),
                .watchOS(.v3)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Clickstream",
            targets: ["Clickstream"]),
    ],
    dependencies: [
        .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", .exact("1.10.2")),
        .package(name: "Reachability", url: "https://github.com/ashleymills/Reachability.swift", from: "5.0.0"),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", .exact("5.12.0")),
        .package(name: "Starscream", url: "https://github.com/daltoniam/Starscream.git", .exact("4.0.4")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Clickstream",
            dependencies: ["SwiftProtobuf", "Reachability", "GRDB", "Starscream"],
            path: "Sources"),
        .testTarget(
            name: "ClickstreamTests",
            dependencies: ["Clickstream"],
            path: "ClickstreamTests",
            exclude: ["Info.plist", "Test Plans"],
            resources: [.process("Resources")])
    ],
    swiftLanguageVersions: [.v5]
)
