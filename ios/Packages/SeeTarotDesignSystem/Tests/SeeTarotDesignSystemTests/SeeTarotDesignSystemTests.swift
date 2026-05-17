import XCTest
import SwiftUI
@testable import SeeTarotDesignSystem

final class SeeTarotDesignSystemTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotDesignSystem.moduleName, "SeeTarotDesignSystem")
    }

    func testDefaultTokensSane() {
        let t = DesignTokens.default
        XCTAssertEqual(t.spacing.md, 16)
        XCTAssertLessThan(t.spacing.sm, t.spacing.lg)
        XCTAssertNotNil(t.palette.accent)
    }

    func testEnvironmentDefaultIsSystemPalette() {
        var env = EnvironmentValues()
        XCTAssertEqual(env.designTokens.spacing.xl, 40)
        env.designTokens = DesignTokens.default
        XCTAssertEqual(env.designTokens.spacing.xs, 4)
    }

    func testComponentsInstantiate() {
        _ = PrimaryButton("Go") {}
        _ = LoadingView("Working")
    }
}
