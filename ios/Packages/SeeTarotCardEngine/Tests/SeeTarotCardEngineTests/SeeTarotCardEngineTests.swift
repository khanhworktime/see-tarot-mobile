import XCTest
@testable import SeeTarotCardEngine

final class SeeTarotCardEngineTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotCardEngine.moduleName, "SeeTarotCardEngine")
    }
}
