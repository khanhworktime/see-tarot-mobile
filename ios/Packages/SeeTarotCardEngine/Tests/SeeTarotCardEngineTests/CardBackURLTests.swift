import XCTest
@testable import SeeTarotCardEngine

final class CardBackURLTests: XCTestCase {

    // MARK: - derive(from:)

    func testDeriveReplacesPathWithBackPng() throws {
        let src = URL(string: "https://api.seetarot.com/cards/the-sun.svg")!
        let back = try XCTUnwrap(CardBackURL.derive(from: src))
        XCTAssertEqual(back.path, "/cards/back.png")
    }

    func testDerivePreservesSchemeAndHost() throws {
        let src = URL(string: "https://api.seetarot.com/cards/the-moon.svg")!
        let back = try XCTUnwrap(CardBackURL.derive(from: src))
        XCTAssertEqual(back.scheme, "https")
        XCTAssertEqual(back.host, "api.seetarot.com")
    }

    func testDerivePreservesPort() throws {
        let src = URL(string: "http://localhost:8080/cards/the-fool.svg")!
        let back = try XCTUnwrap(CardBackURL.derive(from: src))
        XCTAssertEqual(back.port, 8080)
        XCTAssertEqual(back.path, "/cards/back.png")
    }

    func testDeriveStripsQuery() throws {
        let src = URL(string: "https://api.seetarot.com/cards/star.svg?v=2")!
        let back = try XCTUnwrap(CardBackURL.derive(from: src))
        XCTAssertNil(back.query)
    }

    func testDeriveNilInputReturnsNil() {
        XCTAssertNil(CardBackURL.derive(from: nil))
    }

    // MARK: - cacheKey(for:)

    func testCacheKeyFormat() {
        let src = URL(string: "https://api.seetarot.com/cards/world.svg")!
        XCTAssertEqual(CardBackURL.cacheKey(for: src), "_back@api.seetarot.com")
    }

    func testCacheKeyForLocalhost() {
        let src = URL(string: "http://localhost:8080/cards/fool.svg")!
        XCTAssertEqual(CardBackURL.cacheKey(for: src), "_back@localhost")
    }

    func testCacheKeyNilReturnsUnknown() {
        XCTAssertEqual(CardBackURL.cacheKey(for: nil), "_back@unknown")
    }

    func testCacheKeySameHostDifferentCards() {
        let sunURL  = URL(string: "https://api.seetarot.com/cards/sun.svg")!
        let moonURL = URL(string: "https://api.seetarot.com/cards/moon.svg")!
        // Same host → same cache key (one cached back per host)
        XCTAssertEqual(CardBackURL.cacheKey(for: sunURL),
                       CardBackURL.cacheKey(for: moonURL))
    }
}
