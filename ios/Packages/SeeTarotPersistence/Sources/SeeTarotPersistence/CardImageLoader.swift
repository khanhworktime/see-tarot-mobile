import Foundation

/// Offline-tolerant card artwork loader: cache-first, then network, storing on
/// success. Card art is public/static — no bearer; plain ephemeral session
/// (cookie-free, consistent with decision 0006).
public actor CardImageLoader {
    private let cache: ArtworkCache
    private let session: URLSession

    public init(cache: ArtworkCache,
                session: URLSession = CardImageLoader.makeSession()) {
        self.cache = cache
        self.session = session
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
        if let cached = await cache.data(for: cardId) { return cached }
        guard let url else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode), !data.isEmpty else {
                return await cache.data(for: cardId)   // nil here (miss above)
            }
            await cache.store(data, for: cardId)
            return data
        } catch {
            // Airplane mode / transient: fall back to cache (already a miss).
            return await cache.data(for: cardId)
        }
    }
}
