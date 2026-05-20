// CardArt.swift — SeeTarotDesignSystem
//
// Bundled card art helpers: enumerates the five pre-release SVG cards and the
// brand-logo PNG card back. All assets live in Resources/CardArt/ and are
// processed by SPM via the existing `.process("Resources")` rule.
//
// SwiftDraw API used:
//   iOS  — `SVG(named:in:)` + `.rasterize(size:)` → UIImage → Image(uiImage:)
//   macOS— `NSImage(svgNamed:in:)` → Image(nsImage:)
//   PNG  — Bundle.module URL → platform image → Image(…)
//
// Images are rasterized at 285×465 pt (3× card = 95×155). Callers apply
// `.resizable().aspectRatio(contentMode: .fill)` to fit the forced 95/155 frame.

import SwiftUI
import SwiftDraw

// MARK: - BundledCard

/// The five pre-release Major Arcana cards shipped as SVG assets.
public enum BundledCard: String, CaseIterable, Sendable, Hashable {
    case theFool     = "the-fool"
    case theMagician = "the-magician"
    case theStar     = "the-star"
    case theMoon     = "the-moon"
    case theSun      = "the-sun"
}

public extension BundledCard {
    /// Display name for accessibility and decoration labels.
    var displayName: String {
        switch self {
        case .theFool:     return "The Fool"
        case .theMagician: return "The Magician"
        case .theStar:     return "The Star"
        case .theMoon:     return "The Moon"
        case .theSun:      return "The Sun"
        }
    }

    /// Roman numeral arcana identifier.
    var arcanaNumeral: String {
        switch self {
        case .theFool:     return "0"
        case .theMagician: return "I"
        case .theStar:     return "XVII"
        case .theMoon:     return "XVIII"
        case .theSun:      return "XIX"
        }
    }
}

// MARK: - CardArt

/// Static helpers for loading bundled card art as SwiftUI Images.
/// Images are rasterized at 3× the forced 95×155 card frame (285×465 pt).
/// Apply `.resizable().aspectRatio(contentMode: .fill)` at the call site.
public enum CardArt {

    /// Raster target: 3× the forced 95×155 card frame.
    private static let rasterSize = CGSize(width: 285, height: 465)

    // MARK: SVG card faces

    /// Returns a rasterized SwiftUI `Image` for the given bundled card.
    /// Falls back to a system-image placeholder if the SVG cannot be loaded.
    public static func image(for card: BundledCard) -> Image {
        let filename = card.rawValue + ".svg"
        return svgImage(named: filename)
    }

    // MARK: Brand-logo card back

    /// Brand-logo PNG rendered on the card back.
    /// Loaded from `Resources/CardArt/brand-logo.png` in `Bundle.module`.
    public static var brandLogoBack: Image {
        pngImage(named: "brand-logo")
    }

    // MARK: - Private loaders

    /// Loads an SVG from Bundle.module and rasterizes it at `rasterSize`.
    private static func svgImage(named name: String) -> Image {
#if canImport(UIKit)
        guard let svg = SVG(named: name, in: .module) else {
            return Image(systemName: "photo")
        }
        let uiImage = svg.rasterize(size: rasterSize)
        return Image(uiImage: uiImage)
#elseif canImport(AppKit)
        guard let nsImage = NSImage(svgNamed: name, in: .module) else {
            return Image(systemName: "photo")
        }
        return Image(nsImage: nsImage)
#else
        return Image(systemName: "photo")
#endif
    }

    /// Loads a loose PNG by name (without extension) from Bundle.module.
    /// NOTE: SPM `.process("Resources")` flattens directory structure, so the
    /// file lands at the bundle ROOT — do not pass `subdirectory:` (would nil-out).
    private static func pngImage(named name: String) -> Image {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png"
        ) else {
            return Image(systemName: "photo")
        }
#if canImport(UIKit)
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: uiImage)
#elseif canImport(AppKit)
        guard let nsImage = NSImage(contentsOf: url) else {
            return Image(systemName: "photo")
        }
        return Image(nsImage: nsImage)
#else
        return Image(systemName: "photo")
#endif
    }
}
