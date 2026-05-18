import XCTest
@testable import SeeTarotPersistence

/// E03 Phase 02: bounded eviction + offline-tolerant CardImageLoader.
final class ArtworkCacheLoaderTests: XCTestCase {
    private func tmpDir() -> URL {
        let d = FileManager.default.temporaryDirectory
            .appendingPathComponent("artcache-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(
            at: d, withIntermediateDirectories: true)
        return d
    }

    func testEvictionKeepsUnderCapAndSpareJustWritten() async {
        let dir = tmpDir()
        // cap 300B; each blob 200B → only ~1 survives besides just-written.
        let cache = DiskArtworkCache(directory: dir, maxBytes: 300)
        let blob = Data(repeating: 0xAB, count: 200)
        await cache.store(blob, for: "old")
        try? await Task.sleep(nanoseconds: 1_100_000_000) // distinct mtime
        await cache.store(blob, for: "new")

        let total = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.fileSizeKey]))?
            .reduce(0) { $0 + ((try? $1.resourceValues(
                forKeys: [.fileSizeKey]))?.fileSize ?? 0) } ?? 0
        XCTAssertLessThanOrEqual(total, 300)
        let justWritten = await cache.data(for: "new")
        XCTAssertNotNil(justWritten, "just-written file must survive eviction")
        let evicted = await cache.data(for: "old")
        XCTAssertNil(evicted, "older file should be evicted under cap")
    }

    func testCacheRoundTripSurvivesNewInstance() async {
        let dir = tmpDir()
        await DiskArtworkCache(directory: dir).store(Data("img".utf8),
                                                     for: "card-1")
        let fresh = DiskArtworkCache(directory: dir)   // simulate relaunch
        let got = await fresh.data(for: "card-1")
        XCTAssertEqual(got, Data("img".utf8))
    }

    func testLoaderCacheHitNoNetwork() async {
        let dir = tmpDir()
        let cache = DiskArtworkCache(directory: dir)
        await cache.store(Data("cached".utf8), for: "c1")
        // Session that always fails — proves a hit needs no network.
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [AlwaysFailProtocol.self]
        let loader = CardImageLoader(cache: cache,
                                     session: URLSession(configuration: cfg))
        let data = await loader.image(
            cardId: "c1", url: URL(string: "https://x/img.png"))
        XCTAssertEqual(data, Data("cached".utf8))
    }

    func testLoaderNilUrlReturnsNil() async {
        let loader = CardImageLoader(cache: DiskArtworkCache(directory: tmpDir()))
        let data = await loader.image(cardId: "missing", url: nil)
        XCTAssertNil(data)
    }

    func testLoaderOfflineNoCacheReturnsNil() async {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [AlwaysFailProtocol.self]
        let loader = CardImageLoader(
            cache: DiskArtworkCache(directory: tmpDir()),
            session: URLSession(configuration: cfg))
        let data = await loader.image(
            cardId: "c2", url: URL(string: "https://x/y.png"))
        XCTAssertNil(data)
    }

    func testLoaderFetchesStoresThenServesOffline() async {
        let dir = tmpDir()
        let cache = DiskArtworkCache(directory: dir)
        let okCfg = URLSessionConfiguration.ephemeral
        okCfg.protocolClasses = [OKImageProtocol.self]
        let loader = CardImageLoader(cache: cache,
                                     session: URLSession(configuration: okCfg))
        let first = await loader.image(
            cardId: "c3", url: URL(string: "https://x/z.png"))
        XCTAssertEqual(first, OKImageProtocol.payload)
        // Now offline loader over same cache returns the stored bytes.
        let failCfg = URLSessionConfiguration.ephemeral
        failCfg.protocolClasses = [AlwaysFailProtocol.self]
        let offline = CardImageLoader(
            cache: cache, session: URLSession(configuration: failCfg))
        let cached = await offline.image(
            cardId: "c3", url: URL(string: "https://x/z.png"))
        XCTAssertEqual(cached, OKImageProtocol.payload)
    }
}

private final class AlwaysFailProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for r: URLRequest) -> URLRequest { r }
    override func startLoading() {
        client?.urlProtocol(self, didFailWithError:
            URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}

private final class OKImageProtocol: URLProtocol {
    static let payload = Data("PNGBYTES".utf8)
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for r: URLRequest) -> URLRequest { r }
    override func startLoading() {
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200,
                                   httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: OKImageProtocol.payload)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
