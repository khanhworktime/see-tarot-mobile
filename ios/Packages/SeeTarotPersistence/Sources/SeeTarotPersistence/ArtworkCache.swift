import Foundation

/// Immutable, content-addressed disk cache for card artwork (keyed by card id).
/// Bounded by a byte cap with LRU-by-mtime eviction (E03 — the E01 "revisit"
/// note). File-protected on iOS.
public protocol ArtworkCache: Sendable {
    func data(for cardId: String) async -> Data?
    func store(_ data: Data, for cardId: String) async
}

public actor DiskArtworkCache: ArtworkCache {
    private let directory: URL
    private let maxBytes: Int
    private let fm = FileManager.default

    /// - Parameter maxBytes: total on-disk cap; default 64 MB. Tests pass a
    ///   tiny value to exercise eviction.
    public init(directory: URL? = nil, maxBytes: Int = 64 * 1024 * 1024) {
        self.maxBytes = maxBytes
        if let directory {
            self.directory = directory
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory,
                                                  in: .userDomainMask)[0]
            self.directory = caches.appendingPathComponent("see-tarot-artwork",
                                                           isDirectory: true)
        }
        try? fm.createDirectory(at: self.directory,
                                withIntermediateDirectories: true)
    }

    private func url(_ cardId: String) -> URL {
        // card ids are server-controlled; sanitize for filesystem safety.
        let safe = cardId.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent(safe)
    }

    public func data(for cardId: String) async -> Data? {
        let target = url(cardId)
        guard let data = try? Data(contentsOf: target) else { return nil }
        // Read = recency: best-effort mtime bump so re-viewed cards survive
        // eviction longer (LRU-by-mtime).
        try? fm.setAttributes([.modificationDate: Date()],
                              ofItemAtPath: target.path)
        return data
    }

    public func store(_ data: Data, for cardId: String) async {
        let target = url(cardId)
        try? data.write(to: target, options: .atomic)
        #if os(iOS)
        try? fm.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: target.path)
        #endif
        enforceCap(justWrote: target)
    }

    /// Delete oldest-by-mtime files until total ≤ `maxBytes`. Never deletes
    /// the file just written. Serialized by actor isolation (no races).
    private func enforceCap(justWrote: URL) {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let entries = try? fm.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys) else { return }

        var sized: [(url: URL, size: Int, mtime: Date)] = []
        var total = 0
        for file in entries {
            let v = try? file.resourceValues(forKeys: Set(keys))
            let size = v?.fileSize ?? 0
            let mtime = v?.contentModificationDate ?? .distantPast
            sized.append((file, size, mtime))
            total += size
        }
        guard total > maxBytes else { return }

        for entry in sized.sorted(by: { $0.mtime < $1.mtime }) {
            if total <= maxBytes { break }
            if entry.url == justWrote { continue }
            try? fm.removeItem(at: entry.url)
            total -= entry.size
        }
    }
}
