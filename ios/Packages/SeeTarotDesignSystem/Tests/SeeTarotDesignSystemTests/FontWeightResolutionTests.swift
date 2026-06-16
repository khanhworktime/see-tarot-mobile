// FontWeightResolutionTests.swift — H1-A regression guard
// Asserts that the Lora and Cinzel tokens resolve to the expected weight traits
// after FontRegistrar.registerAll(). Fails loudly if a future OS/CoreText change
// breaks font registration or weight resolution.
//
// H1-A resolution behaviour (verified on iOS sim):
//   Lora — single-axis variable font; ONLY PS name is "Lora-Regular". iOS
//           UIFont(name:) does NOT fuzzy-match weights, so both the body and
//           caption tokens use "Lora-Regular" (caption differs by size, not
//           weight). These tests assert the PRODUCTION token names resolve to a
//           real Lora-family font (not a silent system-font fallback).
//   Cinzel — named-instance PS records: "Cinzel-Regular", "CinzelRoman-Bold",
//            "CinzelRoman-Black". UIFont(name:) resolves exactly.
//
// Requires a UIKit host (iOS simulator or device). On a pure macOS test host
// UIFont is unavailable, so the tests are skipped via XCTSkip.

import XCTest
@testable import SeeTarotDesignSystem

#if canImport(UIKit)
import UIKit
import CoreText

final class FontWeightResolutionTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Ensure fonts are registered before resolving. @MainActor call from test host.
        await MainActor.run { FontRegistrar.registerAll() }
    }

    // MARK: - Lora weight-trait assertions

    /// Lora body token uses "Lora-Regular" (exact PostScript name).
    /// Expected UIFont weight trait: ≈ 0.0 (Regular).
    func testLoraBodyTokenResolvesAtRegularWeight() throws {
        let font = UIFont(name: "Lora-Regular", size: 17)
        let resolved = try XCTUnwrap(font,
            "Lora-Regular must resolve — font may not be registered")
        let weightTrait = weightValue(of: resolved)
        XCTAssertEqual(weightTrait, 0.0, accuracy: 0.15,
            "Lora-Regular weight trait \(weightTrait) is not near 0.0 (Regular)")
    }

    /// Caption token uses "Lora-Regular" at 13pt (Lora has no iOS-resolvable
    /// Medium PS name; size differentiates caption from body). This guards the
    /// PRODUCTION token: it must resolve to a real Lora-family font, NOT a silent
    /// system-font fallback (the H1-A bug this regression test exists to catch).
    func testLoraCaptionTokenResolvesToLoraRegular() throws {
        let font = try XCTUnwrap(
            UIFont(name: "Lora-Regular", size: 13),
            "Lora-Regular must resolve — FontRegistrar.registerAll() may have failed")
        let familyName = font.familyName.lowercased()
        XCTAssertTrue(familyName.contains("lora"),
            "Caption font resolved to family '\(font.familyName)' — expected Lora "
            + "(a system-font fallback here is the H1-A production bug)")
        let weightTrait = weightValue(of: font)
        XCTAssertEqual(weightTrait, 0.0, accuracy: 0.15,
            "Lora-Regular weight trait \(weightTrait) is not near 0.0 (Regular)")
    }

    // MARK: - Cinzel exact PostScript-name assertions

    /// Cinzel display token "CinzelRoman-Black" resolves EXACT (named PostScript record).
    /// Expected weight trait: ≈ 0.56 (Black/Heavy on most CoreText versions).
    func testCinzelDisplayTokenResolvesExact() throws {
        let font = UIFont(name: "CinzelRoman-Black", size: 34)
        let resolved = try XCTUnwrap(font,
            "CinzelRoman-Black must resolve exactly — check font registration")
        // Verify it really resolved to the intended family (not a fallback).
        let familyName = resolved.familyName.lowercased()
        XCTAssertTrue(familyName.contains("cinzel"),
            "CinzelRoman-Black resolved to family '\(resolved.familyName)' — expected Cinzel family")
        let weightTrait = weightValue(of: resolved)
        XCTAssertGreaterThan(weightTrait, 0.35,
            "CinzelRoman-Black weight trait \(weightTrait) expected > 0.35 (Bold or heavier)")
    }

    /// Cinzel title token "CinzelRoman-Bold" resolves EXACT.
    func testCinzelTitleTokenResolvesExact() throws {
        let font = UIFont(name: "CinzelRoman-Bold", size: 28)
        let resolved = try XCTUnwrap(font,
            "CinzelRoman-Bold must resolve exactly — check font registration")
        let familyName = resolved.familyName.lowercased()
        XCTAssertTrue(familyName.contains("cinzel"),
            "CinzelRoman-Bold resolved to family '\(resolved.familyName)' — expected Cinzel family")
        let weightTrait = weightValue(of: resolved)
        XCTAssertGreaterThan(weightTrait, 0.2,
            "CinzelRoman-Bold weight trait \(weightTrait) expected > 0.2 (Bold)")
    }

    /// Cinzel heading token "Cinzel-Regular" resolves EXACT.
    func testCinzelHeadingTokenResolvesExact() throws {
        let font = UIFont(name: "Cinzel-Regular", size: 20)
        let resolved = try XCTUnwrap(font,
            "Cinzel-Regular must resolve exactly — check font registration")
        let familyName = resolved.familyName.lowercased()
        XCTAssertTrue(familyName.contains("cinzel"),
            "Cinzel-Regular resolved to family '\(resolved.familyName)' — expected Cinzel family")
    }

    // MARK: - Helper

    /// Extracts the UIFontDescriptor weight trait in the range [-1, 1].
    private func weightValue(of font: UIFont) -> Double {
        let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        return (traits?[.weight] as? Double) ?? 0.0
    }
}

#else

// Non-UIKit host (pure macOS test runner without AppKit font APIs).
// Skip gracefully — the guard runs on iOS simulators in CI.
final class FontWeightResolutionTests: XCTestCase {
    func testSkippedOnNonUIKitHost() throws {
        throw XCTSkip("FontWeightResolutionTests require a UIKit host (iOS simulator)")
    }
}

#endif
