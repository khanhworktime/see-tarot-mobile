// swift-tools-version: 6.0
import PackageDescription

// SeeTarotFeatures: feature modules (Auth, App shell) composing all layers.
let package = Package(
    name: "SeeTarotFeatures",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SeeTarotFeatures", targets: ["SeeTarotFeatures"])],
    dependencies: [
        .package(path: "../SeeTarotCore"),
        .package(path: "../SeeTarotNetworking"),
        .package(path: "../SeeTarotPersistence"),
        .package(path: "../SeeTarotDesignSystem"),
        .package(path: "../SeeTarotCardEngine")
    ],
    targets: [
        .target(
            name: "SeeTarotFeatures",
            dependencies: [
                "SeeTarotCore", "SeeTarotNetworking", "SeeTarotPersistence",
                "SeeTarotDesignSystem", "SeeTarotCardEngine"
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotFeaturesTests",
            dependencies: ["SeeTarotFeatures"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
