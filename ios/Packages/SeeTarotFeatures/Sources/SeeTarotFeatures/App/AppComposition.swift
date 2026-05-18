import Foundation
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence

/// Composition root: wires Keychain token store + Live API client + AuthStore,
/// resolving the client↔store 401 cycle via a small handler box.
public enum AppComposition {
    private final class UnauthorizedBox: @unchecked Sendable {
        var handler: @Sendable () -> Void = {}
        func fire() { handler() }
    }

    @MainActor
    public static func makeAuthStore(baseURL: URL) -> AuthStore {
        let tokenStore = KeychainTokenStore()
        let box = UnauthorizedBox()
        let client = LiveAPIClient(
            baseURL: baseURL, tokenStore: tokenStore,
            onUnauthorized: { box.fire() })
        let store = AuthStore(client: client, tokenStore: tokenStore)
        box.handler = { Task { @MainActor in store.handleUnauthorized() } }
        return store
    }

    #if DEBUG
    /// DEBUG-only: a pre-authenticated store backed by `StubAPIClient` with
    /// deterministic daily + SSE fixtures. Used for offline UI verification /
    /// screenshots (`SEE_TAROT_UI_STUB=1`). Never used in Release.
    @MainActor
    public static func makeStubAuthStore() -> AuthStore {
        let stub = StubAPIClient()
        let user = SessionUser(id: "stub-1", name: "Demo", email: "demo@see.tarot",
                               tier: "plus", subscriptionStatus: nil,
                               subscriptionRenewsAt: nil, kofiEmail: nil,
                               birthDate: "1990-01-01", timezone: "Asia/Saigon",
                               preferredIntent: "general",
                               onboardedAt: "2026-01-01T00:00:00Z")
        stub.sessionUser = user
        let card = ReadingCard(id: "c1", name: "The Sun", arcana: "major",
                               suit: nil, number: 19, imageUrl: nil,
                               position: 0, reversed: false, keywords: ["joy"],
                               uprightMeaning: "u", reversedMeaning: "r")
        stub.dailyTodayResult = Reading(
            id: "d1", userId: "stub-1", kind: "daily", spread: "single",
            intent: "general", question: nil,
            interpretation: "The Sun brings clarity and warmth to your day. "
                + "Lead with optimism.", model: "stub", tier: "plus",
            isPublic: false, createdAt: "2026-05-17T00:00:00Z",
            cards: [card], reflections: nil, isOwner: true)
        stub.sseScript = [
            SSEEvent(name: "card", data: Data(#"""
            {"id":"c1","name":"The Star","arcana":"major","suit":null,\
            "number":17,"imageUrl":null,"position":0,"reversed":false,\
            "keywords":["hope"],"uprightMeaning":"u","reversedMeaning":"r"}
            """#.utf8)),
            SSEEvent(name: "delta", data: Data(#"{"delta":"Hope guides "}"#.utf8)),
            SSEEvent(name: "delta", data: Data(#"{"delta":"your path."}"#.utf8)),
            SSEEvent(name: "done", data: Data(#"{"readingId":"r1"}"#.utf8))
        ]
        // E03 history/reflection fixtures for offline UI verification.
        stub.historyPages = [
            nil: HistoryPage(items: [
                HistoryPage.Row(id: "d1", kind: "daily", spread: "single",
                                intent: "general", question: nil,
                                preview: "The Sun brings clarity and warmth.",
                                createdAt: "2026-05-17T00:00:00Z"),
                HistoryPage.Row(id: "o1", kind: "oracle", spread: "single",
                                intent: "career", question: "Next step?",
                                preview: "The Star points to renewed hope.",
                                createdAt: "2026-05-16T00:00:00Z")
            ], nextCursor: nil)
        ]
        stub.readingResult = .success(stub.dailyTodayResult!)
        stub.reflectionsResult = [
            Reflection(id: "rf1", body: "Felt grounded after this one.",
                       mood: "calm", createdAt: "2026-05-17T08:00:00Z")
        ]
        // E04: profile save echoes back so the stub UI works offline.
        stub.updateProfileResult = .success(user)
        // Token present ⇒ bootstrap() hydrates via the stub → authenticated.
        let store = AuthStore(client: stub,
                              tokenStore: InMemoryTokenStore(token: "stub"))
        return store
    }
    #endif
}
