import SwiftUI
import SeeTarotDesignSystem

/// Ambient cosmic background. E01 ships a lightweight SwiftUI animated-gradient
/// implementation (60fps, no Metal toolchain dependency). The Metal shader
/// path is deferred (decision: Metal scoped to ambient bg only, 0004;
/// `xcodebuild -downloadComponent MetalToolchain` required — see HARNESS_BACKLOG
/// / phase-06). The view API stays stable so swapping in Metal later is
/// non-breaking.
public struct AmbientBackgroundView: View {
    @Environment(\.designTokens) private var tokens
    @State private var animate = false

    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [
                tokens.palette.accent.opacity(0.35),
                tokens.palette.background,
                tokens.palette.accent.opacity(0.15)
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading)
        .ignoresSafeArea()
        .animation(tokens.motion.ambient, value: animate)
        .onAppear { animate = true }
    }
}
