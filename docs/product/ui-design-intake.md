# UI Design Intake — SeeTarot iOS Visual Redesign

Status: ACCEPTED brainstorm (2026-05-19). Input type: **Change request** (re-skin
wired surfaces, no contract change). Lane: **normal**. Living doc — update on
change. Feeds a story packet (UI redesign epic); does not alter API/state seams.

## Work Item

Re-skin all wired iOS surfaces to the SeeTarot brand vibe. Behavior, networking,
auth, stores, navigation graph **unchanged** — this is presentation only. Card
geometry and artwork rules are hard constraints.

Affected docs: `product/overview.md`, `product/readings.md`,
`decisions/0004` (CardSurface seam). Affected code seams (do not reshape):
`SeeTarotCardEngine/CardSurface.swift` + `RealCardSurface`,
`DesignSystem/Tokens.swift`, `History/CardImage.swift`, `Reading/ReadingView.swift`.

## Hard Constraints (non-negotiable)

| Constraint | Rule |
| --- | --- |
| Background color | `#010726` for screen background **and** card surface fill. |
| Card aspect ratio | Force **95 / 155** (≈0.613). Accept artwork stretch — fill, do not letterbox. Apply same stretch to card back. |
| Card back image | `/cards/back.png` served from the **same host as `ReadingCard.imageUrl`** — derive base at runtime from that URL's scheme+host (do not hardcode). |
| Card name label | Artwork has **no baked label** → always render card name below each card; reversed → show reversed state (label + 180° artwork). |
| Per-card info source | **No metadata endpoint exists.** Render from `ReadingCard` fields already in the reading payload (`keywords`, `uprightMeaning`, `reversedMeaning`, `arcana`, `suit`, `number`). No extra fetch. |
| Celtic spread | Hidden in v1 (BE `403 celtic_coming_soon`). Design the ritual to scale to celtic, but ship only 1-card & 3-card. |

## Design System

### Vibe
**Cosmic Mysticism** — deep-space depth, starfield, reactive particle glow,
constellation accents. Immersive but legible.

### Color (Moonlight Silver on cosmic navy)
| Token | Hex | Use |
| --- | --- | --- |
| `bg` | `#010726` | screen + card surface |
| `bgLayer1` / `bgLayer2` | `#050B2E` / `#0A1140` | glass tint, depth layering |
| `accent` (silver) | `#C9D2E3` | primary accent, icons, hairlines |
| `accentBright` | `#E8EDF7` | active/selected, glow core, primary text |
| `accentDim` | `#8A93A8` | secondary text, inactive |
| `starlight` | `#FFFFFF` @ low α | particles, sparkle, constellation |

Replace the current indigo `DesignTokens.Palette` brand values with these. Keep
the **token injection pattern** (environment, not singletons) intact.

### Typography
**Display/heading: Cinzel. Body: Lora.** Both SIL OFL — **bundle the `.ttf`
files into the app** (Info.plist `UIAppFonts`); do NOT load from Google Fonts
CDN at runtime (offline/perf). System `.serif` (New York) is the fallback if a
glyph/weight is missing. Must respect Dynamic Type (scale bundled fonts via
`UIFontMetrics`, no truncation as text scales). Tabular figures for quota
counts / timers.

### Surfaces — Glassmorphic (with contrast guard)
`.ultraThinMaterial` panels over the starfield, tinted toward `bgLayer1`, with a
1px `accent` hairline + soft outer glow. **Contrast guard:** body/interpretation
text never sits directly on blur — it sits on an inner near-opaque scrim
(`bg` @ ≥0.82) so foreground text holds **≥4.5:1**; secondary ≥3:1. Verify both
in-context, not in isolation.

### Ornament — Moderate
Celestial accents (moon/stars), glyph dividers at ritual beats, corner
flourishes only at ceremonial moments. Functional UI stays clean. SVG/vector
only — no emoji icons. One icon family, consistent stroke.

### Motion — Premium, purposeful
Rich at ritual beats (shuffle, fan, hold-to-focus, flip, reveal); restrained on
routine screens (150–300ms micro-interactions). Full `prefers-reduced-motion`
path (particles → static gradient; flips → crossfade). Animations interruptible,
never block input, never cause layout shift.

### Background — Reactive particle glow
Touch-reactive particle field + slow drift. **Metal toolchain is absent in build
env (decision/observation S1776)** → implement with SwiftUI `TimelineView` +
`Canvas` (CPU particle field), not Metal. Provide static-gradient fallback for
reduced-motion and low-power. Budget: stay ≥60fps on iPhone 12-class; cap
particle count; pause off-screen.

## Signature Interactions

### Card reveal
3D Y-axis flip from `back.png` → face, with a silver glow burst at the half-flip
threshold. Single shared `FlipCardView` (extends existing `RealCardSurface`
seam) at the forced 95/155 frame.

### Spread ritual (Oracle 1-card / 3-card; celtic-ready)
1. **Shuffle** — deck riffles/scatters (particle reactive).
2. **Fan** — cards arc out into the spread.
3. **Hold-to-focus** — user presses & holds the deck; particles converge inward
   while held (the "deep breath" beat); release → deal + sequential flip.
   **Reduced-motion: skip the hold beat entirely → go straight to deal.**
4. 3-card: flip left→right with staggered reveal (30–50ms stagger).

### AI interpretation (SSE = whole-reading result)
Stream is one complete reading. Parse the `delta` text by markdown `###`
headings into ordered **block sections**; render each as a sequential
**magic-reveal** block (fade + rise as it streams in), not one undivided blob.
Cards row pinned above with names beneath each. Tapping a card opens a detail
sheet rendered from the in-payload `ReadingCard` (keywords, upright/reversed
meaning, arcana/suit/number) — no network call.

## Navigation

Immersive hub + bottom bar. **Bottom bar (4 tabs, icon+label):**
`Today · Oracle · History · Profile`. **Home = Today**, Daily card as the large
center anchor; Oracle/History reachable from the bar. Current tab visually
active; back behavior preserves scroll/state; deep links unchanged.

## Surfaces to Redesign (all wired)

Auth/SignIn · Onboarding · Home (Today, Daily anchor) · OracleForm · ReadingView
(Oracle SSE) · DailySection · QuotaChip · History list · ReadingDetail +
Reflections · Profile · error/retry states (`502 ai_failed`, `403` entitlement,
`429`) · offline (cached artwork/readings) · empty states.

## Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Glass + `#010726` + silver → low contrast | Inner opaque scrim under all text; verify ≥4.5:1 in-context per screen, both states. |
| CPU particle field perf/battery | Canvas/TimelineView impl, capped count, off-screen pause, reduced-motion + low-power static fallback. |
| Forced 95/155 distorts artwork | Accepted by stakeholder; apply identical stretch to back.png for consistency. |
| Card-back base URL | Resolved: same host as `ReadingCard.imageUrl`; derive scheme+host at runtime. |
| Celtic absent in v1 | Ship 1/3-card only; ritual built to scale, celtic entry gated/hidden. |

## Resolved Decisions (2026-05-19)

1. Card-back base URL = same host as `ReadingCard.imageUrl` (runtime-derived).
2. Fonts = **Cinzel (display) + Lora (body)**, SIL OFL, bundled `.ttf` (not CDN).
3. Reduced-motion for hold-to-focus = skip the hold beat, go straight to deal.
4. Home (Today) has a **direct Oracle CTA** alongside the Daily anchor (plus the
   Oracle bottom-bar tab).
5. Card-back artwork load reuses `CardImageLoader` with synthetic key
   `_back@<host>` (cache-first; no protocol/seam change).
6. Cinzel + Lora `.ttf` + OFL committed at
   `ios/Packages/SeeTarotDesignSystem/Sources/SeeTarotDesignSystem/Resources/Fonts/`.

No open questions.
