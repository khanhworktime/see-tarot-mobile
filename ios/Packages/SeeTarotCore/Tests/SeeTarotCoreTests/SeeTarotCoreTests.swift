import XCTest
@testable import SeeTarotCore

final class SeeTarotCoreTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotCore.moduleName, "SeeTarotCore")
    }
}
