// SeeTarotFeatures — Auth + app shell. Filled in Phase 05.
import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence
import SeeTarotDesignSystem
import SeeTarotCardEngine

public enum SeeTarotFeatures {
    public static let moduleName = "SeeTarotFeatures"
}

/// Placeholder root view; replaced by RootView in Phase 05.
public struct FoundationRootView: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 8) {
            Text("See Tarot").font(.largeTitle.bold())
            Text("Harness v0 — iOS foundation").foregroundStyle(.secondary)
        }
    }
}
