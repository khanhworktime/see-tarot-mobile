import XCTest
@testable import SeeTarotPersistence

final class SeeTarotPersistenceTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotPersistence.moduleName, "SeeTarotPersistence")
    }
}
