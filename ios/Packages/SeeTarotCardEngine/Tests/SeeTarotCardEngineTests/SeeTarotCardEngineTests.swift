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
}
