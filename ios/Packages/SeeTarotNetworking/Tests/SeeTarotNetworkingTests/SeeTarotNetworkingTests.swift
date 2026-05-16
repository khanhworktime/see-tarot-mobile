import XCTest
@testable import SeeTarotNetworking

final class SeeTarotNetworkingTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotNetworking.moduleName, "SeeTarotNetworking")
    }
}
