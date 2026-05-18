import Foundation
import SwiftData

/// SwiftData container. E01 keeps the schema to one trivial model to prove the
/// container + migration path; reading/history models arrive in E02/E03 (a
/// reset is harmless now — decision: SwiftData over GRDB, 0004).
@Model
public final class CachedFlag {
    public var key: String
    public var value: Bool
    public var updatedAt: Date

    public init(key: String, value: Bool, updatedAt: Date = .now) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}

public enum PersistenceContainer {
    public static let schema = Schema([CachedFlag.self])

    /// App container (on-disk). `inMemory` is used by unit tests.
    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema,
                                        isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Shared offline card-artwork loader (bounded disk cache) for Features.
    public static func makeArtworkLoader(
        maxBytes: Int = 64 * 1024 * 1024) -> CardImageLoader {
        CardImageLoader(cache: DiskArtworkCache(maxBytes: maxBytes))
    }
}
