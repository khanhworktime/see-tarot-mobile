// FontWeightResolutionTests.swift — H1-A regression guard
// Asserts that the Lora and Cinzel tokens resolve to the expected weight traits
// after FontRegistrar.registerAll(). Fails loudly if a future OS/CoreText change
// stops fuzzy-resolving "Lora-Medium" (or exact Cinzel names) at the expected
// weight. Guards the correctness documented in Tokens.swift H1-A comment.
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

    /// Lora caption token uses "Lora-Medium" — resolved via CoreText fuzzy matching
    /// on macOS/iOS to the Medium instance (wght≈500). Expected trait: ≈ 0.2.
    /// This test is the CI guard described in H1-A: if CoreText stops fuzzy-resolving
    /// "Lora-Medium" to the true Medium weight, this test will fail and alert the team.
    func testLoraCaptionTokenResolvesAtMediumWeight() throws {
        let font = UIFont(name: "Lora-Medium", size: 13)
        let resolved = try XCTUnwrap(font,
            "Lora-Medium must resolve via CoreText fuzzy matching")
        let weightTrait = weightValue(of: resolved)
        // UIFont weight trait for Medium is approximately 0.2 on current CoreText.
        // Tolerance of 0.15 accommodates minor platform variation while catching
        // a regression to Regular (trait ≈ 0.0) or Bold (trait ≈ 0.4+).
        XCTAssertGreaterThan(weightTrait, 0.05,
            "Lora-Medium resolved at weight \(weightTrait) — expected > 0.05 (Medium); CoreText fuzzy resolution may have regressed")
        XCTAssertLessThan(weightTrait, 0.35,
            "Lora-Medium resolved at weight \(weightTrait) — expected < 0.35 (not Bold); unexpected weight resolution")
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
