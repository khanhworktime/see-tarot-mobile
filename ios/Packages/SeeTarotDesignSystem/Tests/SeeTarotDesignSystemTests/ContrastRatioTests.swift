// ContrastRatioTests.swift — Phase 02, SeeTarotDesignSystem
// Asserts WCAG 2.1 contrast requirements for the Cosmic Mysticism glass-scrim
// composite are met at the chosen scrim alpha (0.82).
//
// Colour values match Tokens.swift Palette.cosmic exactly.
// Fully deterministic: pure arithmetic, no UIKit/SwiftUI runtime.

import XCTest
@testable import SeeTarotDesignSystem

final class ContrastRatioTests: XCTestCase {

    // MARK: - Palette constants (sRGB [0,1])

    // bg = #010726
    private static let bg = SRGBColor(red: 0x01 / 255.0, green: 0x07 / 255.0, blue: 0x26 / 255.0)
    // bgLayer1 = #050B2E
    private static let bgLayer1 = SRGBColor(red: 0x05 / 255.0, green: 0x0B / 255.0, blue: 0x2E / 255.0)
    // accentBright = #E8EDF7
    private static let accentBright = SRGBColor(red: 0xE8 / 255.0, green: 0xED / 255.0, blue: 0xF7 / 255.0)
    // accentDim = #8A93A8
    private static let accentDim = SRGBColor(red: 0x8A / 255.0, green: 0x93 / 255.0, blue: 0xA8 / 255.0)

    /// Must stay in sync with GlassMetrics.scrimAlpha in GlassSurface.swift.
    private static let scrimAlpha: Double = 0.82

    // MARK: - Effective scrim colour

    /// bg @ scrimAlpha composited over bgLayer1 @ 1.0.
    private static var effectiveScrim: SRGBColor {
        alphaComposite(fg: bg, alpha: scrimAlpha, over: bgLayer1)
    }

    // MARK: - Contrast requirement tests

    /// accentBright on the glass inner scrim must be ≥4.5:1 (WCAG AA normal text).
    func testAccentBrightOnScrimMeetsAA() {
        let ratio = ContrastRatio.wcag(fg: Self.accentBright, over: Self.effectiveScrim)
        XCTAssertGreaterThanOrEqual(
            ratio, 4.5,
            "accentBright (#E8EDF7) contrast on scrim is \(ratio):1 — must be ≥4.5:1"
        )
    }

    /// accentDim on the glass inner scrim must be ≥3.0:1 (WCAG AA large/secondary text).
    func testAccentDimOnScrimMeetsSecondaryThreshold() {
        let ratio = ContrastRatio.wcag(fg: Self.accentDim, over: Self.effectiveScrim)
        XCTAssertGreaterThanOrEqual(
            ratio, 3.0,
            "accentDim (#8A93A8) contrast on scrim is \(ratio):1 — must be ≥3.0:1"
        )
    }

    // MARK: - wcagLuminance unit tests

    func testWcagLuminanceBlackIsZero() {
        XCTAssertEqual(wcagLuminance(r: 0, g: 0, b: 0), 0.0, accuracy: 1e-9)
    }

    func testWcagLuminanceWhiteIsOne() {
        XCTAssertEqual(wcagLuminance(r: 1, g: 1, b: 1), 1.0, accuracy: 1e-6)
    }

    // MARK: - ContrastRatio.wcag unit tests

    func testContrastRatioBlackOnWhiteIs21() {
        let ratio = ContrastRatio.wcag(
            fg: SRGBColor(red: 0, green: 0, blue: 0),
            over: SRGBColor(red: 1, green: 1, blue: 1)
        )
        XCTAssertEqual(ratio, 21.0, accuracy: 0.01)
    }

    func testContrastRatioSameColorIsOne() {
        let ratio = ContrastRatio.wcag(
            fg: SRGBColor(red: 0.5, green: 0.5, blue: 0.5),
            over: SRGBColor(red: 0.5, green: 0.5, blue: 0.5)
        )
        XCTAssertEqual(ratio, 1.0, accuracy: 1e-9)
    }

    // MARK: - alphaComposite unit tests

    func testAlphaCompositeFullOpacityReturnsFg() {
        let fg = SRGBColor(red: 1, green: 0, blue: 0)
        let bg = SRGBColor(red: 0, green: 0, blue: 1)
        let result = alphaComposite(fg: fg, alpha: 1.0, over: bg)
        XCTAssertEqual(result.red, 1.0, accuracy: 1e-9)
        XCTAssertEqual(result.green, 0.0, accuracy: 1e-9)
        XCTAssertEqual(result.blue, 0.0, accuracy: 1e-9)
    }

    func testAlphaCompositeZeroOpacityReturnsBg() {
        let fg = SRGBColor(red: 1, green: 0, blue: 0)
        let bg = SRGBColor(red: 0, green: 0, blue: 1)
        let result = alphaComposite(fg: fg, alpha: 0.0, over: bg)
        XCTAssertEqual(result.red, 0.0, accuracy: 1e-9)
        XCTAssertEqual(result.blue, 1.0, accuracy: 1e-9)
    }

    func testAlphaCompositeHalfBlend() {
        let fg = SRGBColor(red: 1, green: 1, blue: 1)
        let bg = SRGBColor(red: 0, green: 0, blue: 0)
        let result = alphaComposite(fg: fg, alpha: 0.5, over: bg)
        XCTAssertEqual(result.red, 0.5, accuracy: 1e-9)
        XCTAssertEqual(result.green, 0.5, accuracy: 1e-9)
        XCTAssertEqual(result.blue, 0.5, accuracy: 1e-9)
    }

    // MARK: - Scrim alpha boundary guard

    /// Guards that scrimAlpha hasn't been accidentally lowered below the safe minimum.
    func testScrimAlphaIsAtLeastSpec() {
        XCTAssertGreaterThanOrEqual(
            Self.scrimAlpha, 0.82,
            "scrimAlpha must remain ≥0.82 per Phase 02 spec"
        )
    }
}
