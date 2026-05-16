import XCTest
@testable import SeeTarotCore

final class SeeTarotCoreTests: XCTestCase {
    private let dec = JSONDecoder.api
    private let enc = JSONEncoder.api

    func testModuleLoads() {
        XCTAssertEqual(SeeTarotCore.moduleName, "SeeTarotCore")
    }

    // MARK: Quota — Infinity ⇒ null on wire ⇒ unlimited

    func testQuotaNullOracleRemainingIsUnlimited() throws {
        let json = #"{"tier":"plus","dailyRemaining":1,"oracleRemaining":null}"#
        let q = try dec.decode(Quota.self, from: Data(json.utf8))
        XCTAssertTrue(q.isOracleUnlimited)
        XCTAssertEqual(q.dailyRemaining, 1)
    }

    func testQuotaMissingOracleRemainingIsUnlimited() throws {
        let json = #"{"tier":"plus","dailyRemaining":0}"#
        let q = try dec.decode(Quota.self, from: Data(json.utf8))
        XCTAssertTrue(q.isOracleUnlimited)
    }

    func testQuotaFiniteOracleRemaining() throws {
        let json = #"{"tier":"free","dailyRemaining":1,"oracleRemaining":3}"#
        let q = try dec.decode(Quota.self, from: Data(json.utf8))
        XCTAssertFalse(q.isOracleUnlimited)
        XCTAssertEqual(q.oracleRemaining, 3)
    }

    // MARK: Error envelope

    func testErrorEnvelopeWithoutOptionalFields() throws {
        let json = #"{"error":"unauthorized"}"#
        let e = try dec.decode(APIErrorEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(e.error, "unauthorized")
        XCTAssertNil(e.message)
        XCTAssertNil(e.issues)
    }

    func testErrorEnvelopeWithZodIssues() throws {
        let json = #"""
        {"error":"bad_request","message":"invalid","issues":[{"path":["question"],"message":"too short","code":"too_small"}]}
        """#
        let e = try dec.decode(APIErrorEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(e.issues?.first?.path, ["question"])
        XCTAssertEqual(e.issues?.first?.code, "too_small")
    }

    // MARK: SessionUser onboarding

    func testSessionUserNeedsOnboardingWhenOnboardedAtNil() throws {
        let json = #"{"user":{"id":"u1","email":"a@b.co","onboardedAt":null}}"#
        let env = try dec.decode(SessionEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(env.user?.id, "u1")
        XCTAssertTrue(env.user?.needsOnboarding == true)
    }

    func testSessionEnvelopeNullUser() throws {
        let env = try dec.decode(SessionEnvelope.self, from: Data(#"{"user":null}"#.utf8))
        XCTAssertNil(env.user)
    }

    // MARK: ReadingInput round-trip + client validation

    func testReadingInputRoundTrip() throws {
        let input = ReadingInput(kind: .oracle, spread: .three, intent: .love,
                                 question: "Will my path improve soon?")
        let data = try enc.encode(input)
        let back = try dec.decode(ReadingInput.self, from: data)
        XCTAssertEqual(back, input)
    }

    func testDailyRejectsQuestionAndNonSingle() {
        XCTAssertNotNil(ReadingInput(kind: .daily, spread: .three, intent: .general)
            .clientValidationError)
        XCTAssertNil(ReadingInput(kind: .daily, spread: .single, intent: .general)
            .clientValidationError)
    }

    func testOracleRequiresQuestion() {
        XCTAssertNotNil(ReadingInput(kind: .oracle, spread: .single, intent: .career,
                                     question: "short").clientValidationError)
        XCTAssertNil(ReadingInput(kind: .oracle, spread: .single, intent: .career,
                                  question: "Where should I focus my energy now?")
            .clientValidationError)
    }

    func testCelticHidden() {
        XCTAssertNotNil(ReadingInput(kind: .oracle, spread: .celtic, intent: .general,
                                     question: "A long enough question here?")
            .clientValidationError)
    }

    // MARK: Reading + SSE payloads decode

    func testReadingDecodesWithCards() throws {
        let json = #"""
        {"id":"r1","userId":"u1","kind":"oracle","spread":"single","intent":"love",
         "question":null,"interpretation":"text","model":"m","tier":"plus",
         "isPublic":false,"createdAt":"2026-05-17T00:00:00Z","isOwner":true,
         "cards":[{"id":"c1","name":"The Sun","arcana":"major","suit":null,
         "number":19,"imageUrl":null,"position":0,"reversed":false,
         "keywords":["joy"],"uprightMeaning":"u","reversedMeaning":"r"}],
         "reflections":null}
        """#
        let r = try dec.decode(Reading.self, from: Data(json.utf8))
        XCTAssertEqual(r.cards.count, 1)
        XCTAssertEqual(r.cards[0].name, "The Sun")
        XCTAssertNil(r.cards[0].suit)
    }

    func testSSEDonePayload() throws {
        let d = try dec.decode(SSEPayload.Done.self,
                               from: Data(#"{"readingId":"r9","model":"x"}"#.utf8))
        XCTAssertEqual(d.readingId, "r9")
    }
}
