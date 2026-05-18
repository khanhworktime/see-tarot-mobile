// swift-tools-version: 6.0
import PackageDescription

// SeeTarotPersistence: Keychain token store, SwiftData container, artwork cache.
let package = Package(
    name: "SeeTarotPersistence",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SeeTarotPersistence", targets: ["SeeTarotPersistence"])],
    dependencies: [
        .package(path: "../SeeTarotCore"),
        .package(path: "../SeeTarotNetworking"),
        // Pure-Swift SVG rasterizer: BE serves card artwork as image/svg+xml,
        // which iOS cannot decode at runtime (decision: HARNESS_BACKLOG
        // "iOS runtime SVG artwork rendering").
        .package(url: "https://github.com/swhitty/SwiftDraw", from: "0.27.0")
    ],
    targets: [
        .target(
            name: "SeeTarotPersistence",
            dependencies: ["SeeTarotCore", "SeeTarotNetworking",
                           .product(name: "SwiftDraw", package: "SwiftDraw")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotPersistenceTests",
            dependencies: ["SeeTarotPersistence"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
