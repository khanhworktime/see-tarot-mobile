// LiquidGlass.swift — DesignSystem / Phase 09 (Login Overhaul)
//
// Provides `.liquidGlass(cornerRadius:tint:)` and `.liquidGlassButton(cornerRadius:)`.
//
// Rendering paths:
//   iOS 26+  → Apple native Liquid Glass via `glassEffect(_:in:)`.
//              When tint == nil: untinted Glass.regular — full depth transparency.
//              When tint != nil: Glass.regular.tint(color) — brand-tinted glass.
//   iOS 17–25 → `.ultraThinMaterial` + bgLayer1 tint @0.30 + silver hairline + outer glow.
//              Opacity reduced from 0.55 → 0.30 (Phase 2 tuning) so floating cards +
//              breathing bubbles read through the panel.
//
// NOTE: `glassEffect` is iOS 26 API. The call site is guarded with
// `#available(iOS 26, *)` so the SPM host build (macOS 13) never sees it.
// SourceKit may flag it as unknown — trust `swift build` output per env rules.

import SwiftUI

// MARK: - LiquidGlassModifier

/// Applies a depth glass surface. On iOS 26+ uses native Liquid Glass;
/// on iOS 17–25 falls back to `.ultraThinMaterial` with brand tinting.
/// - Parameters:
///   - cornerRadius: Corner radius of the glass shape. Default 24.
///   - tint: Optional tint. `nil` → iOS 26 uses untinted Glass (full depth);
///           iOS 17–25 uses bgLayer1 @0.30. Pass a Color to override on both paths.
public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    let cornerRadius: CGFloat
    let tint: Color?

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        // iOS 26+ : native Liquid Glass via `.glassEffect(_:in:)`.
        // tint == nil → use Glass.regular (untinted — full depth transparency).
        // tint != nil → apply brand tint via .tint(_:).
        #if os(iOS)
        if #available(iOS 26.0, *) {
            let glass: Glass = if let tint {
                Glass.regular.tint(tint)
            } else {
                Glass.regular
            }
            return AnyView(
                content
                    .glassEffect(glass, in: shape)
            )
        }
        #endif
        // Fallback tint: explicit tint or bgLayer1 @0.30 (reduced from 0.55 in Phase 2).
        let fallbackTint = tint ?? tokens.palette.bgLayer1
        return AnyView(fallback(content: content, shape: shape, tint: fallbackTint))
    }

    private func fallback(
        content: Content,
        shape: RoundedRectangle,
        tint: Color
    ) -> some View {
        content
            .background(
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    // Phase 2: reduced from 0.55 → 0.30 so background depth reads through.
                    shape.fill(tint.opacity(0.30))
                }
            )
            .overlay(
                shape.strokeBorder(
                    tokens.palette.accentSilver.opacity(0.4),
                    lineWidth: 1
                )
            )
            .shadow(
                color: tokens.palette.accentSilver.opacity(0.12),
                radius: 16,
                x: 0,
                y: 0
            )
    }
}

// MARK: - LiquidGlassButtonModifier

/// Button-tuned variant: slightly more saturated tint + scale-press feedback.
/// Wrap button label content with this; do not apply to `Button` directly to
/// avoid double-press-state conflicts with built-in SwiftUI button styles.
public struct LiquidGlassButtonModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    let cornerRadius: CGFloat
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .modifier(
                LiquidGlassModifier(
                    cornerRadius: cornerRadius,
                    tint: tokens.palette.bgLayer2   // deeper tint → more saturated
                )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - View extension

public extension View {
    /// Applies a glass depth surface. iOS 26+ → native Liquid Glass.
    /// iOS 17–25 → ultraThinMaterial fallback with brand tint @0.30 + hairline.
    ///
    /// - Parameters:
    ///   - cornerRadius: Shape corner radius. Default 24.
    ///   - tint: Override tint. Pass `nil` (default) for iOS 26 untinted depth glass;
    ///           fallback path uses bgLayer1 @0.30.
    ///
    /// - Important: This modifier handles depth only.
    ///   Place `ScrimText` inside for text with ≥4.5:1 contrast guarantee.
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        tint: Color? = nil
    ) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }

    /// Button-tuned glass: deeper tint + scale-press (0.97) feedback.
    func liquidGlassButton(cornerRadius: CGFloat = 24) -> some View {
        modifier(LiquidGlassButtonModifier(cornerRadius: cornerRadius))
    }
}
