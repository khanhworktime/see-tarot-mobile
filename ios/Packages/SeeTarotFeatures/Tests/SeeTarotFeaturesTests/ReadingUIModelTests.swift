import XCTest
import SeeTarotCore
@testable import SeeTarotFeatures

final class ReadingUIModelTests: XCTestCase {
    func testIntentCopyCoversAllSevenIntents() {
        XCTAssertEqual(IntentCopy.all.count, ReadingInput.Intent.allCases.count)
        for intent in ReadingInput.Intent.allCases {
            let copy = IntentCopy.copy(for: intent)
            XCTAssertEqual(copy.intent, intent)
            XCTAssertFalse(copy.label.isEmpty)
            XCTAssertFalse(copy.detail.isEmpty)
        }
    }

    func testQuotaDisplayUnlimitedHidesNumber() {
        let q = Quota(tier: "plus", dailyRemaining: 1, oracleRemaining: nil)
        let d = QuotaDisplay(q)
        XCTAssertEqual(d.tierText, "Plus")
        XCTAssertEqual(d.dailyText, "Daily 1")
        XCTAssertEqual(d.oracleText, "Oracle ∞")
    }

    func testQuotaDisplayFiniteShowsNumber() {
        let d = QuotaDisplay(Quota(tier: "free", dailyRemaining: 0,
                                   oracleRemaining: 3))
        XCTAssertEqual(d.oracleText, "Oracle 3")
    }
}
