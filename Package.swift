// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clickstream",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Core SDK.
        .library(name: "Clickstream", targets: ["Clickstream"]),
        // Optional: health tracking. Link alongside `Clickstream`.
        .library(name: "Tracker", targets: ["Tracker"]),
        // Optional: event visualizer UI. Link alongside `Clickstream`.
        .library(name: "ClickstreamEventVisualizer", targets: ["ClickstreamEventVisualizer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.0"),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.7.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.5"),
        .package(url: "https://github.com/gojek/courier-iOS.git", exact: "1.0.25")
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
            path: "Sources/Clickstream"
        ),
        .target(
            name: "Tracker",
            dependencies: [
                "Clickstream",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Tracker"
        ),
        .target(
            name: "ClickstreamEventVisualizer",
            dependencies: [
                "Clickstream",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Sources/EventVisualizer"
        )
    ],
    swiftLanguageVersions: [.v5]
)
