// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Clickstream",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Clickstream", targets: ["Clickstream"])
    ],
    // Optional features, the SPM equivalent of the podspec subspecs. Clients opt in with
    // `.package(url: "https://github.com/gojek/clickstream-ios.git", from: "x.y.z", traits: ["Tracker"])`.
    traits: [
        // Nothing is enabled unless the client asks for it.
        .default(enabledTraits: []),
        .trait(name: "Tracker", description: "SDK health tracking. Equivalent to the Clickstream/Tracker subspec."),
        .trait(name: "EventVisualizer", description: "Event visualizer UI. Equivalent to the Clickstream/EventVisualizer subspec.")
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
            path: "Sources",
            exclude: [
                "Example",
                "ETETestSuite"
            ],
            swiftSettings: [
                .define("TRACKER_ENABLED", .when(traits: ["Tracker"])),
                .define("EVENT_VISUALIZER_ENABLED", .when(traits: ["EventVisualizer"]))
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
