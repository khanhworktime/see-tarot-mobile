// swift-tools-version: 6.0
import PackageDescription

// SeeTarotNetworking: API client protocol, live/stub clients, SSE primitive.
let package = Package(
    name: "SeeTarotNetworking",
    platforms: [.iOS(.v17)],
    products: [.library(name: "SeeTarotNetworking", targets: ["SeeTarotNetworking"])],
    dependencies: [.package(path: "../SeeTarotCore")],
    targets: [
        .target(
            name: "SeeTarotNetworking",
            dependencies: ["SeeTarotCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotNetworkingTests",
            dependencies: ["SeeTarotNetworking"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
