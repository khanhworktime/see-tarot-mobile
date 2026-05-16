import XCTest
import SwiftData
import SeeTarotNetworking
@testable import SeeTarotPersistence

/// In-memory fake so the token store is testable without an entitled host.
private final class FakeKeychain: KeychainAccessing, @unchecked Sendable {
    private var store: [String: String] = [:]
    func read(_ key: String) -> String? { store[key] }
    func write(_ key: String, _ value: String) { store[key] = value }
    func delete(_ key: String) { store[key] = nil }
}

final class SeeTarotPersistenceTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(SeeTarotPersistence.moduleName, "SeeTarotPersistence")
    }

    // MARK: KeychainTokenStore conforms to Networking.TokenStoring

    func testTokenStoreRoundTrip() {
        let store: TokenStoring = KeychainTokenStore(keychain: FakeKeychain())
        XCTAssertNil(store.token)
        store.setToken("abc")
        XCTAssertEqual(store.token, "abc")
        store.setToken(nil)            // clears
        XCTAssertNil(store.token)
        store.setToken("")             // empty ⇒ delete
        XCTAssertNil(store.token)
    }

    // MARK: SwiftData container

    func testInMemoryContainerInsertAndFetch() throws {
        let container = try PersistenceContainer.make(inMemory: true)
        let ctx = ModelContext(container)
        ctx.insert(CachedFlag(key: "seen-intro", value: true))
        try ctx.save()
        let rows = try ctx.fetch(FetchDescriptor<CachedFlag>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.key, "seen-intro")
        XCTAssertTrue(rows.first?.value == true)
    }

    // MARK: Artwork disk cache

    func testArtworkCacheStoreReadMiss() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("art-\(UUID().uuidString)", isDirectory: true)
        let cache = DiskArtworkCache(directory: tmp)
        let miss = await cache.data(for: "card-1")
        XCTAssertNil(miss)
        let payload = Data("PNGDATA".utf8)
        await cache.store(payload, for: "card-1")
        let hit = await cache.data(for: "card-1")
        XCTAssertEqual(hit, payload)
        try? FileManager.default.removeItem(at: tmp)
    }
}
