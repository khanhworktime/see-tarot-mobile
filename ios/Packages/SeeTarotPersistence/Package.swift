// swift-tools-version: 6.0
import PackageDescription

// SeeTarotPersistence: Keychain token store, SwiftData container, artwork cache.
let package = Package(
    name: "SeeTarotPersistence",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "SeeTarotPersistence", targets: ["SeeTarotPersistence"])],
    dependencies: [
        .package(path: "../SeeTarotCore"),
        .package(path: "../SeeTarotNetworking")
    ],
    targets: [
        .target(
            name: "SeeTarotPersistence",
            dependencies: ["SeeTarotCore", "SeeTarotNetworking"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotPersistenceTests",
            dependencies: ["SeeTarotPersistence"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
