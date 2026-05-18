import Foundation
import OSLog
import SwiftDraw

private let log = Logger(subsystem: "com.seetarot.app", category: "artwork")

/// Offline-tolerant card artwork loader: cache-first, then network, storing on
/// success. Card art is public/static — no bearer; plain ephemeral session
/// (cookie-free, consistent with decision 0006). BE serves `image/svg+xml`;
/// SVG is rasterized to PNG once on fetch so the cache holds decodable bytes
/// and offline render needs no SVG engine.
public actor CardImageLoader {
    private let cache: ArtworkCache
    private let session: URLSession
    private let maxBytes: Int

    /// Real card SVGs are ~365–450 KB; cap well above that and reject larger
    /// payloads before handing untrusted bytes to the SVG rasterizer
    /// (defense-in-depth vs a malformed/oversized response).
    public init(cache: ArtworkCache,
                session: URLSession = CardImageLoader.makeSession(),
                maxBytes: Int = 3 * 1024 * 1024) {
        self.cache = cache
        self.session = session
        self.maxBytes = maxBytes
    }

    public static func makeSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.httpCookieStorage = nil
        cfg.httpShouldSetCookies = false
        return URLSession(configuration: cfg)
    }

    /// - Returns: image bytes, or `nil` when there is no cache, no URL, or the
    ///   network fails with nothing cached (caller shows a placeholder).
    public func image(cardId: String, url: URL?) async -> Data? {
        // Only trust cached bytes that are a decodable raster. Pre-SVG builds
        // (or partial writes) may have cached raw SVG/garbage — treat those as
        // a miss so the fetch path re-rasterizes and overwrites (self-heal).
        if let cached = await cache.data(for: cardId), Self.isRaster(cached) {
            log.debug("hit \(cardId, privacy: .public)")
            return cached
        }
        guard let url else {
            log.debug("nil-url \(cardId, privacy: .public)")
            return nil
        }
        do {
            let (data, response) = try await session.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            log.debug("fetch \(cardId, privacy: .public) http=\(code) bytes=\(data.count)")
            guard (200...299).contains(code), !data.isEmpty else {
                return await staleSafeCache(cardId)
            }
            guard data.count <= maxBytes else {
                log.error("oversize \(cardId, privacy: .public) bytes=\(data.count) > \(self.maxBytes)")
                return await staleSafeCache(cardId)
            }
            let raster = Self.rasterizedIfSVG(data)
            log.debug("raster \(cardId, privacy: .public) svg→png=\(raster?.count ?? -1)")
            let bytes = raster ?? data
            guard Self.isRaster(bytes) else { return nil }   // undecodable → placeholder
            await cache.store(bytes, for: cardId)
            return bytes
        } catch {
            log.error("err \(cardId, privacy: .public) \(error.localizedDescription, privacy: .public)")
            return await staleSafeCache(cardId)
        }
    }

    /// Cache read that only yields a usable raster (ignores stale SVG bytes).
    private func staleSafeCache(_ cardId: String) async -> Data? {
        guard let d = await cache.data(for: cardId), Self.isRaster(d) else {
            return nil
        }
        return d
    }

    /// True if bytes start with a PNG or JPEG signature (a natively
    /// decodable raster). Guards against stale SVG / partial cache entries.
    nonisolated static func isRaster(_ data: Data) -> Bool {
        let png: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let jpeg: [UInt8] = [0xFF, 0xD8, 0xFF]
        let head = [UInt8](data.prefix(4))
        return head.starts(with: png) || head.starts(with: jpeg)
    }

    /// If `data` is SVG, rasterize to PNG @2x (retina) so the cache holds
    /// natively-decodable bytes. Returns nil when not SVG or rasterization
    /// fails (caller keeps the original bytes).
    nonisolated static func rasterizedIfSVG(_ data: Data) -> Data? {
        let head = data.prefix(256)
        guard let text = String(data: head, encoding: .utf8),
              text.contains("<svg") || text.contains("<?xml") else {
            return nil
        }
        guard let svg = SVG(data: data) else { return nil }
        return try? svg.pngData(scale: 2)   // @2x retina, intrinsic size
    }
}
