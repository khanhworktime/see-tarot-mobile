// swift-tools-version: 6.0
import PackageDescription

// SeeTarotDesignSystem: design tokens + shared SwiftUI components.
let package = Package(
    name: "SeeTarotDesignSystem",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "SeeTarotDesignSystem", targets: ["SeeTarotDesignSystem"])],
    targets: [
        .target(
            name: "SeeTarotDesignSystem",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SeeTarotDesignSystemTests",
            dependencies: ["SeeTarotDesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
