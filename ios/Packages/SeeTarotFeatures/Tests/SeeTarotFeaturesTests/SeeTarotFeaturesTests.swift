import XCTest
@testable import SeeTarotFeatures

final class SeeTarotFeaturesTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotFeatures.moduleName, "SeeTarotFeatures")
    }
}
