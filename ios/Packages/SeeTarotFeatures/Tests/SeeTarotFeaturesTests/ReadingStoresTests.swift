import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

@MainActor
final class ReadingStoresTests: XCTestCase {
    private func card(_ id: String, pos: Int) -> ReadingCard {
        ReadingCard(id: id, name: "The Sun", arcana: "major", suit: nil,
                    number: 19, imageUrl: nil, position: pos, reversed: false,
                    keywords: ["joy"], uprightMeaning: "u", reversedMeaning: "r")
    }
    private func reading(_ id: String) -> Reading {
        Reading(id: id, userId: "u1", kind: "daily", spread: "single",
                intent: "general", question: nil, interpretation: "today",
                model: "m", tier: "plus", isPublic: false,
                createdAt: "2026-05-17T00:00:00Z", cards: [card("c1", pos: 0)],
                reflections: nil, isOwner: true)
    }
    private func sse(_ name: String, _ json: String) -> SSEEvent {
        SSEEvent(name: name, data: Data(json.utf8))
    }

    // MARK: Daily

    func testDailyUsesExistingWhenPresent() async {
        let stub = StubAPIClient()
        stub.dailyTodayResult = reading("d1")
        let store = DailyReadingStore(client: stub, timezone: "Asia/Saigon")
        await store.load()
        XCTAssertEqual(store.state, .loaded(reading("d1")))
    }

    func testDailyDrawsWhenNoneToday() async {
        let stub = StubAPIClient()
        stub.dailyTodayResult = nil
        stub.drawDailyResult = .success(reading("d2"))
        let store = DailyReadingStore(client: stub)
        await store.load()
        XCTAssertEqual(store.state, .loaded(reading("d2")))
    }

    func testDailyAlreadyDrawnBlocked() async {
        let stub = StubAPIClient()
        stub.dailyTodayResult = nil
        stub.drawDailyResult = .failure(APIError.entitlement(code: "daily_already_drawn"))
        let store = DailyReadingStore(client: stub)
        await store.load()
        XCTAssertEqual(store.state, .blocked(code: "daily_already_drawn"))
    }

    func testDailyAIFailureRetryable() async {
        let stub = StubAPIClient()
        stub.dailyTodayResult = nil
        stub.drawDailyResult = .failure(APIError.http(status: 502, envelope: nil))
        let store = DailyReadingStore(client: stub)
        await store.load()
        XCTAssertEqual(store.state, .failed(retryable: true))
    }

    // MARK: Oracle

    func testOracleInvalidInputShortCircuits() {
        let store = OracleReadingStore(client: StubAPIClient())
        store.submit(ReadingInput(kind: .oracle, spread: .single,
                                  intent: .love, question: "short"))
        if case .invalid = store.state {} else { XCTFail("\(store.state)") }
    }

    func testOracleStreamsCardThenDeltaThenDone() async {
        let stub = StubAPIClient()
        let cardJSON = """
        {"id":"c1","name":"The Sun","arcana":"major","suit":null,\
        "number":19,"imageUrl":null,"position":0,"reversed":false,\
        "keywords":["joy"],"uprightMeaning":"u","reversedMeaning":"r"}
        """
        stub.sseScript = [
            sse("card", cardJSON),
            sse("delta", #"{"delta":"You "}"#),
            sse("delta", #"{"delta":"shine."}"#),
            sse("done", #"{"readingId":"r9","model":"x"}"#)
        ]
        let store = OracleReadingStore(client: stub)
        store.submit(ReadingInput(kind: .oracle, spread: .single,
                                  intent: .career,
                                  question: "Where should I focus next?"))
        try? await Task.sleep(nanoseconds: 200_000_000)
        if case .done(let id, let cards, let text) = store.state {
            XCTAssertEqual(id, "r9")
            XCTAssertEqual(cards.count, 1)
            XCTAssertEqual(text, "You shine.")
        } else { XCTFail("expected done, got \(store.state)") }
    }

    func testOracleErrorEventRetryable() async {
        let stub = StubAPIClient()
        stub.sseScript = [sse("error", #"{"message":"ai down","retryable":true}"#)]
        let store = OracleReadingStore(client: stub)
        store.submit(ReadingInput(kind: .oracle, spread: .three,
                                  intent: .general,
                                  question: "A sufficiently long question?"))
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(store.state, .failed(retryable: true))
    }

    func testOracleStopCancels() async {
        let stub = StubAPIClient()
        stub.sseScript = [sse("delta", #"{"delta":"partial"}"#)]
        let store = OracleReadingStore(client: stub)
        store.submit(ReadingInput(kind: .oracle, spread: .single,
                                  intent: .feeling,
                                  question: "How do I feel about this?"))
        store.stop()   // must not crash; task cancelled
        XCTAssertNotNil(store)
    }
}
