import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

@MainActor
final class ProfileStoreTests: XCTestCase {
    private func user(name: String? = nil, bd: String? = nil,
                      tz: String? = nil, intent: String? = nil)
        -> SessionUser {
        SessionUser(id: "u1", name: name, email: "u@see.tarot",
                    tier: "plus", birthDate: bd, timezone: tz,
                    preferredIntent: intent,
                    onboardedAt: "2026-01-01T00:00:00Z")
    }

    private func makeAuth(_ u: SessionUser) async -> (AuthStore, StubAPIClient) {
        let stub = StubAPIClient()
        stub.sessionUser = u
        let auth = AuthStore(client: stub,
                             tokenStore: InMemoryTokenStore(token: "t"))
        await auth.bootstrap()
        return (auth, stub)
    }

    func testCleanFormCannotSave() async {
        let u = user(name: "Neo", bd: "1990-01-01", tz: "Asia/Saigon",
                     intent: "career")
        let (auth, _) = await makeAuth(u)
        let store = ProfileStore(auth: auth, user: u)
        XCTAssertFalse(store.isDirty)
        XCTAssertFalse(store.canSave)
    }

    func testDirtyValidEnablesSaveAndSendsOnlyChanged() async {
        let u = user(name: "Neo", bd: "1990-01-01", tz: "Asia/Saigon",
                     intent: "career")
        let (auth, stub) = await makeAuth(u)
        let store = ProfileStore(auth: auth, user: u)
        store.preferredIntent = "love"            // single dirty field
        XCTAssertTrue(store.isDirty)
        XCTAssertTrue(store.canSave)
        await store.save()
        XCTAssertEqual(store.phase, .saved)
        let patch = stub.lastUpdateProfilePatch
        XCTAssertEqual(patch?.preferredIntent, "love")
        XCTAssertNil(patch?.name)
        XCTAssertNil(patch?.timezone)
        XCTAssertEqual(auth.state.user?.preferredIntent, "love")
    }

    func testValidationBounds() {
        func errs(_ n: String?, _ b: String?, _ t: String?, _ i: String?) -> Int {
            ProfileValidation.errors(name: n, birthDate: b, timezone: t,
                                     preferredIntent: i).count
        }
        XCTAssertEqual(errs(nil, nil, nil, nil), 1)               // ≥1 required
        XCTAssertEqual(errs("", nil, nil, nil), 1)                // name <1
        XCTAssertEqual(errs("A", nil, nil, nil), 0)               // name 1 ok
        XCTAssertEqual(errs(String(repeating: "x", count: 60), nil, nil, nil), 0)
        XCTAssertEqual(errs(String(repeating: "x", count: 61), nil, nil, nil), 1)
        XCTAssertEqual(errs(nil, "1990-1-1", nil, nil), 1)        // bad date
        XCTAssertEqual(errs(nil, "1990-01-01", nil, nil), 0)      // good date
        XCTAssertEqual(errs(nil, nil, String(repeating: "z", count: 65), nil), 1)
        XCTAssertEqual(errs(nil, nil, "UTC", nil), 0)
        XCTAssertEqual(errs(nil, nil, nil, "weird"), 1)           // bad intent
        XCTAssertEqual(errs(nil, nil, nil, "feeling"), 0)
    }

    func testInvalidFieldBlocksSave() async {
        let u = user(name: "Neo")
        let (auth, _) = await makeAuth(u)
        let store = ProfileStore(auth: auth, user: u)
        store.name = String(repeating: "x", count: 61)
        XCTAssertFalse(store.validationErrors.isEmpty)
        XCTAssertFalse(store.canSave)
    }

    func testSave400MapsFieldErrors() async throws {
        let u = user(name: "Neo")
        let (auth, stub) = await makeAuth(u)
        let env = try XCTUnwrap(try? JSONDecoder().decode(
            APIErrorEnvelope.self, from: Data(
            #"{"error":"invalid body","issues":[{"path":["name"],"message":"nope"}]}"#.utf8)))
        stub.updateProfileResult = .failure(
            APIError.http(status: 400, envelope: env))
        let store = ProfileStore(auth: auth, user: u)
        store.name = "Trinity"
        await store.save()
        XCTAssertEqual(store.fieldErrors[.name], "nope")
        if case .failed = store.phase {} else { XCTFail("expected failed") }
    }

    func testSave401NoInlineNoCrash() async {
        let u = user(name: "Neo")
        let (auth, stub) = await makeAuth(u)
        stub.updateProfileResult = .failure(APIError.unauthorized)
        let store = ProfileStore(auth: auth, user: u)
        store.name = "Trinity"
        await store.save()
        XCTAssertEqual(store.phase, .idle)
        XCTAssertTrue(store.fieldErrors.isEmpty)
    }
}
