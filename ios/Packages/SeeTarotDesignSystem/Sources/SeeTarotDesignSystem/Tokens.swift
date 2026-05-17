import SwiftUI

/// Design tokens: native iOS (HIG) base + See Tarot brand accent
/// (decision 0004 / product overview). Values, not singletons — injected via
/// the SwiftUI environment.
public struct DesignTokens: Sendable {
    public struct Palette: Sendable {
        public let accent: Color
        public let background: Color
        public let surface: Color
        public let textPrimary: Color
        public let textSecondary: Color

        /// Brand accent (mystic indigo) + platform-semantic neutrals.
        public static var system: Palette {
            #if os(iOS)
            Palette(accent: Color(red: 0.42, green: 0.36, blue: 0.78),
                    background: Color(uiColor: .systemBackground),
                    surface: Color(uiColor: .secondarySystemBackground),
                    textPrimary: Color(uiColor: .label),
                    textSecondary: Color(uiColor: .secondaryLabel))
            #else
            Palette(accent: Color(red: 0.42, green: 0.36, blue: 0.78),
                    background: Color(nsColor: .windowBackgroundColor),
                    surface: Color(nsColor: .underPageBackgroundColor),
                    textPrimary: Color(nsColor: .labelColor),
                    textSecondary: Color(nsColor: .secondaryLabelColor))
            #endif
        }
    }

    public struct Typography: Sendable {
        public let title = Font.largeTitle.bold()
        public let heading = Font.title2.bold()
        public let body = Font.body
        public let caption = Font.footnote
    }

    public struct Spacing: Sendable {
        public let xs: CGFloat = 4
        public let sm: CGFloat = 8
        public let md: CGFloat = 16
        public let lg: CGFloat = 24
        public let xl: CGFloat = 40
    }

    public struct Motion: Sendable {
        public let quick = Animation.easeOut(duration: 0.2)
        public let standard = Animation.easeInOut(duration: 0.35)
        public let ambient = Animation.easeInOut(duration: 6).repeatForever(autoreverses: true)
    }

    public let palette: Palette
    public let typography = Typography()
    public let spacing = Spacing()
    public let motion = Motion()

    public static let `default` = DesignTokens(palette: .system)
}

private struct DesignTokensKey: EnvironmentKey {
    static let defaultValue = DesignTokens.default
}

public extension EnvironmentValues {
    var designTokens: DesignTokens {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}
