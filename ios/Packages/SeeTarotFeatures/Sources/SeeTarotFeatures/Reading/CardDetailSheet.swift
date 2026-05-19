// CardDetailSheet.swift — Phase 06
// Modal detail for a single ReadingCard — rendered purely from in-payload
// fields. Zero network calls. Presented via .sheet from ReadingView.

import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotDesignSystem

// MARK: - CardDetailSheet

/// Full-bleed sheet presenting one `ReadingCard`'s metadata and meaning.
///
/// Layout (top → bottom):
///   • Card art (RealCardSurface, centred, face-up)
///   • Name + arcana / suit / number badge row
///   • Keyword chips
///   • Upright or reversed meaning block (per `card.reversed`)
public struct CardDetailSheet: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.dismiss) private var dismiss

    let card: ReadingCard

    public init(card: ReadingCard) {
        self.card = card
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: tokens.spacing.lg) {
                // ── Drag handle — tappable close affordance (L1) ───────────
                // The capsule doubles as a real Button that calls dismiss(),
                // satisfying both pointer/touch users and VoiceOver (explicit
                // accessibilityLabel). Swipe-to-dismiss remains active
                // (no .interactiveDismissDisabled is set).
                Button {
                    dismiss()
                } label: {
                    Capsule()
                        .fill(tokens.palette.accentSilver.opacity(0.4))
                        .frame(width: 40, height: 4)
                        .padding(.top, tokens.spacing.sm)
                        .contentShape(Rectangle().size(width: 80, height: 44))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")

                // ── Card art ───────────────────────────────────────────────
                RealCardSurface(name: card.name, reversed: card.reversed)
                    .cardView(
                        imageURL: card.imageUrl.flatMap(URL.init),
                        faceUp: true,
                        position: card.position
                    )
                    .accessibilityLabel(artAccessibilityLabel)

                // ── Name + metadata badges ─────────────────────────────────
                GlassSurface {
                    VStack(spacing: tokens.spacing.xs) {
                        ScrimText(card.name, style: .title)

                        HStack(spacing: tokens.spacing.sm) {
                            BadgePill(label: arcanaLabel)
                            if let suitLabel {
                                BadgePill(label: suitLabel)
                            }
                            if let numberLabel {
                                BadgePill(label: numberLabel)
                            }
                        }
                    }
                }
                .glassPanel()
                .padding(.horizontal, tokens.spacing.md)

                // ── Keywords ───────────────────────────────────────────────
                if !card.keywords.isEmpty {
                    GlassSurface {
                        VStack(alignment: .leading, spacing: tokens.spacing.sm) {
                            ScrimText("Keywords", style: .heading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            FlowLayout(spacing: tokens.spacing.sm) {
                                ForEach(card.keywords, id: \.self) { keyword in
                                    KeywordChip(text: keyword)
                                }
                            }
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, tokens.spacing.md)
                }

                // ── Meaning block ──────────────────────────────────────────
                GlassSurface {
                    VStack(alignment: .leading, spacing: tokens.spacing.sm) {
                        ScrimText(meaningHeading, style: .heading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ScrimText(activeMeaning, style: .body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .glassPanel()
                .padding(.horizontal, tokens.spacing.md)

                Spacer(minLength: tokens.spacing.lg)
            }
        }
        .background(tokens.palette.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden) // custom handle above
    }

    // MARK: - Computed properties

    private var arcanaLabel: String {
        card.arcana.capitalized + " Arcana"
    }

    private var suitLabel: String? {
        card.suit.map { $0.capitalized }
    }

    private var numberLabel: String? {
        card.number.map { "No. \($0)" }
    }

    private var meaningHeading: String {
        card.reversed ? "Reversed Meaning" : "Upright Meaning"
    }

    private var activeMeaning: String {
        card.reversed ? card.reversedMeaning : card.uprightMeaning
    }

    private var artAccessibilityLabel: String {
        var parts = [card.name]
        if card.reversed { parts.append("reversed") }
        parts.append(arcanaLabel)
        if let suit = card.suit { parts.append(suit) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - BadgePill

/// Small pill label for arcana / suit / number metadata.
private struct BadgePill: View {
    @Environment(\.designTokens) private var tokens
    let label: String

    var body: some View {
        Text(label)
            .font(tokens.typography.caption)
            .glassText(secondary: true)
            .padding(.horizontal, tokens.spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tokens.palette.accentSilver.opacity(0.15))
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.35),
                                  lineWidth: 1)
            )
    }
}

// MARK: - KeywordChip

/// Rounded keyword tag for the keywords flow row.
private struct KeywordChip: View {
    @Environment(\.designTokens) private var tokens
    let text: String

    var body: some View {
        Text(text.capitalized)
            .font(tokens.typography.caption)
            .glassText()
            .padding(.horizontal, tokens.spacing.sm)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tokens.palette.accentBright.opacity(0.12))
                    .strokeBorder(tokens.palette.accentBright.opacity(0.3),
                                  lineWidth: 1)
            )
    }
}

// MARK: - FlowLayout

/// Wrapping horizontal flow for keyword chips.
/// Sizes chips intrinsically; wraps to the next line when width is exhausted.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout Void) -> CGSize {
        let containerWidth = proposal.width ?? 300
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                totalHeight = currentY
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight

        return CGSize(width: containerWidth, height: max(totalHeight, 0))
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout Void) {
        let containerWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        _ = containerWidth // suppress warning
    }
}
