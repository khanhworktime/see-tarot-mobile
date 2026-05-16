// swift-tools-version: 6.0
import PackageDescription

// SeeTarotCore: pure domain models + coding. No internal dependencies.
let package = Package(
    name: "SeeTarotCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "SeeTarotCore", targets: ["SeeTarotCore"])
    ],
    targets: [
        .target(
            name: "SeeTarotCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotCoreTests",
            dependencies: ["SeeTarotCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
