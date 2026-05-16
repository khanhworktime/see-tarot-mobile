import Foundation

/// Immutable, content-addressed disk cache for card artwork (keyed by card id).
/// No eviction in E01 (YAGNI; revisit E03). File-protected.
public protocol ArtworkCache: Sendable {
    func data(for cardId: String) async -> Data?
    func store(_ data: Data, for cardId: String) async
}

public actor DiskArtworkCache: ArtworkCache {
    private let directory: URL
    private let fm = FileManager.default

    public init(directory: URL? = nil) {
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
        try? Data(contentsOf: url(cardId))
    }

    public func store(_ data: Data, for cardId: String) async {
        let target = url(cardId)
        try? data.write(to: target, options: .atomic)
        #if os(iOS)
        try? fm.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: target.path)
        #endif
    }
}
