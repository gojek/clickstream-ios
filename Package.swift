// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Clickstream",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "Clickstream",
            targets: ["Clickstream"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.7.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.5"),
        .package(url: "https://github.com/gojek/courier-iOS.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Clickstream",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "CourierCore", package: "courier-iOS"),
                .product(name: "CourierMQTT", package: "courier-iOS")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ClickstreamTests",
            dependencies: ["Clickstream"],
            path: "ClickstreamTests",
            exclude: ["Info.plist"])
    ],
    swiftLanguageModes: [.v5]
)
