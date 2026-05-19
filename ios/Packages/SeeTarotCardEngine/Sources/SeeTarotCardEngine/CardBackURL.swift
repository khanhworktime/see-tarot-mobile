import Foundation

/// Pure helper: derives the `/cards/back.png` URL from any card image URL.
/// Keeps the same scheme + host (+ port) as the source URL — no arbitrary
/// hosts, no hardcoded base.
public enum CardBackURL {
    /// Returns `<scheme>://<host>[:<port>]/cards/back.png`, or `nil` when
    /// `imageURL` is `nil` or cannot be parsed into URLComponents.
    public static func derive(from imageURL: URL?) -> URL? {
        guard let imageURL else { return nil }
        var comps = URLComponents(url: imageURL, resolvingAgainstBaseURL: false)
        comps?.path = "/cards/back.png"
        comps?.query = nil
        comps?.fragment = nil
        return comps?.url
    }

    /// Synthetic cache key used by `CardImageLoader` for the card back.
    /// Format: `_back@<host>` — one entry per host, shared across all cards.
    public static func cacheKey(for imageURL: URL?) -> String {
        guard let host = imageURL.flatMap({
            URLComponents(url: $0, resolvingAgainstBaseURL: false)?.host
        }), !host.isEmpty else {
            return "_back@unknown"
        }
        return "_back@\(host)"
    }
}
