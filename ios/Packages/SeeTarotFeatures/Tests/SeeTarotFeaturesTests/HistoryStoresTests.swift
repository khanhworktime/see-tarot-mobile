import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

@MainActor
final class HistoryStoresTests: XCTestCase {
    private func row(_ id: String) -> HistoryPage.Row {
        HistoryPage.Row(id: id, kind: "daily", spread: "single",
                        intent: nil, question: nil, preview: "p",
                        createdAt: "2026-05-18T05:00:00Z")
    }

    private func reading(isPublic: Bool = false) -> Reading {
        Reading(id: "rd1", userId: "u1", kind: "oracle", spread: "single",
                intent: "general", question: "q", interpretation: "text",
                model: "m", tier: "plus", isPublic: isPublic,
                createdAt: "2026-05-18T05:00:00Z", cards: [],
                reflections: nil, isOwner: true)
    }

    // MARK: HistoryStore pagination

    func testHistoryPagesThenStopsOnNullCursor() async {
        let stub = StubAPIClient()
        stub.historyPages = [
            nil: HistoryPage(items: [row("a")], nextCursor: "c1"),
            "c1": HistoryPage(items: [row("b")], nextCursor: nil)
        ]
        let store = HistoryStore(client: stub, limit: 20)
        await store.loadFirst()
        XCTAssertEqual(store.state, .loaded([row("a")]))
        await store.loadMore()
        XCTAssertEqual(store.state, .end([row("a"), row("b")]))
        await store.loadMore()   // no-op past end
        XCTAssertEqual(store.rows.count, 2)
    }

    func testHistoryEmpty() async {
        let stub = StubAPIClient()
        stub.historyPages = [nil: HistoryPage(items: [], nextCursor: nil)]
        let store = HistoryStore(client: stub)
        await store.loadFirst()
        XCTAssertEqual(store.state, .empty)
    }

    func testHistoryErrorRetryable() async {
        let stub = StubAPIClient()
        stub.historyError = APIError.transport("down")
        let store = HistoryStore(client: stub)
        await store.loadFirst()
        XCTAssertEqual(store.state, .error(retryable: true))
    }

    // MARK: ReadingDetailStore

    func testDetailLoadsAndTogglesVisibility() async {
        let stub = StubAPIClient()
        stub.readingResult = .success(reading(isPublic: false))
        stub.visibilityResult = true
        let store = ReadingDetailStore(client: stub)
        await store.load(id: "rd1")
        XCTAssertEqual(store.state, .loaded(reading(isPublic: false)))
        await store.toggleVisibility()
        XCTAssertEqual(store.state, .loaded(reading(isPublic: true)))
    }

    func testDetailNotFound() async {
        let stub = StubAPIClient()
        stub.readingResult = .failure(APIError.http(status: 404,
                                                    envelope: nil))
        let store = ReadingDetailStore(client: stub)
        await store.load(id: "missing")
        XCTAssertEqual(store.state, .notFound)
    }

    // MARK: ReflectionsStore validation + add

    func testReflectionValidationBoundaries() {
        let store = ReflectionsStore(client: StubAPIClient(),
                                     readingId: "rd1")
        XCTAssertFalse(store.validate(body: "ab", mood: nil).isEmpty)   // <3
        XCTAssertTrue(store.validate(body: "abc", mood: nil).isEmpty)   // 3 ok
        XCTAssertTrue(store.validate(body: String(repeating: "x",
                                                  count: 2000),
                                     mood: nil).isEmpty)                // 2000 ok
        XCTAssertFalse(store.validate(body: String(repeating: "x",
                                                   count: 2001),
                                      mood: nil).isEmpty)               // >2000
        XCTAssertFalse(store.validate(body: "   ", mood: nil).isEmpty)  // ws-only
        XCTAssertFalse(store.validate(body: "valid body",
                                      mood: String(repeating: "m",
                                                   count: 25)).isEmpty) // mood>24
    }

    func testAddReflectionRefetchesOnSuccess() async {
        let stub = StubAPIClient()
        stub.addReflectionResult = .success("ref-1")
        stub.reflectionsResult = [
            Reflection(id: "ref-1", body: "saved note", mood: nil,
                       createdAt: "2026-05-18T05:00:00Z")
        ]
        let store = ReflectionsStore(client: stub, readingId: "rd1")
        let ok = await store.add(body: "a real reflection", mood: " ")
        XCTAssertTrue(ok)
        XCTAssertEqual(store.state,
                       .loaded([Reflection(id: "ref-1", body: "saved note",
                                           mood: nil,
                                           createdAt: "2026-05-18T05:00:00Z")]))
    }

    func testAddReflectionBlockedByValidation() async {
        let store = ReflectionsStore(client: StubAPIClient(),
                                     readingId: "rd1")
        let ok = await store.add(body: "no", mood: nil)
        XCTAssertFalse(ok)
        XCTAssertFalse(store.issues.isEmpty)
    }
}
