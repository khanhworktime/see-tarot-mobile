import XCTest
import SwiftUI
@testable import SeeTarotCardEngine

final class SeeTarotCardEngineTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotCardEngine.moduleName, "SeeTarotCardEngine")
    }

    func testAmbientBackgroundInstantiates() {
        _ = AmbientBackgroundView()
    }

    func testPlaceholderCardSurfaceProducesView() {
        let surface = PlaceholderCardSurface()
        _ = surface.cardView(imageURL: nil, faceUp: true, position: 0)
    }

    func testRealCardSurfaceProducesView() {
        let surface = RealCardSurface(name: "The Sun", reversed: false)
        _ = surface.cardView(imageURL: nil, faceUp: false, position: 1)
    }

    // MARK: FlipDecision (pure logic — the testable core of the animation)

    func testNoChangeWhenFaceUnchanged() {
        XCTAssertEqual(FlipDecision.style(wasFaceUp: true, isFaceUp: true,
                                          reduceMotion: false), .none)
    }

    func testThreeDFlipWhenMotionAllowed() {
        XCTAssertEqual(FlipDecision.style(wasFaceUp: false, isFaceUp: true,
                                          reduceMotion: false), .threeDFlip)
    }

    func testCrossFadeWhenReduceMotion() {
        XCTAssertEqual(FlipDecision.style(wasFaceUp: false, isFaceUp: true,
                                          reduceMotion: true), .crossFade)
    }
}
