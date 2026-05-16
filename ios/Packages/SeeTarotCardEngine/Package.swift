// swift-tools-version: 6.0
import PackageDescription

// SeeTarotCardEngine: card animation seam + Metal ambient background.
let package = Package(
    name: "SeeTarotCardEngine",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "SeeTarotCardEngine", targets: ["SeeTarotCardEngine"])],
    dependencies: [.package(path: "../SeeTarotDesignSystem")],
    targets: [
        .target(
            name: "SeeTarotCardEngine",
            dependencies: ["SeeTarotDesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotCardEngineTests",
            dependencies: ["SeeTarotCardEngine"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
