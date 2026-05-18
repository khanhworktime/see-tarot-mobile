import XCTest
@testable import SeeTarotCore

/// Guards the E03 contract reconciliation: `Reflection` must decode the live
/// shape `{id, body, mood?, createdAt}` (no `readingId`/`userId`), and a
/// `Reading` with the leaner reflections must still decode (E02 unaffected).
final class ReflectionDecodeTests: XCTestCase {
    func testReflectionDecodesContractShape() throws {
        let json = Data("""
        {"id":"r1","body":"a quiet note","mood":"calm",
         "createdAt":"2026-05-18T05:00:00Z"}
        """.utf8)
        let r = try JSONDecoder().decode(Reflection.self, from: json)
        XCTAssertEqual(r.id, "r1")
        XCTAssertEqual(r.body, "a quiet note")
        XCTAssertEqual(r.mood, "calm")
    }

    func testReflectionDecodesWithoutMood() throws {
        let json = Data("""
        {"id":"r2","body":"no mood here","createdAt":"2026-05-18T05:00:00Z"}
        """.utf8)
        let r = try JSONDecoder().decode(Reflection.self, from: json)
        XCTAssertNil(r.mood)
    }

    func testReadingDecodesWithLeanReflections() throws {
        let json = Data("""
        {"id":"rd1","userId":"u1","kind":"oracle","spread":"single",
         "intent":"general","question":"q","interpretation":"text",
         "model":"m","tier":"plus","isPublic":false,
         "createdAt":"2026-05-18T05:00:00Z","cards":[],
         "reflections":[{"id":"r1","body":"hi there",
         "createdAt":"2026-05-18T05:00:00Z"}],"isOwner":true}
        """.utf8)
        let reading = try JSONDecoder().decode(Reading.self, from: json)
        XCTAssertEqual(reading.reflections?.first?.id, "r1")
    }
}
