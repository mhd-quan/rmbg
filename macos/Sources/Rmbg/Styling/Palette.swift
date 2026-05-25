import SwiftUI

/// Semantic color tokens. Most colors defer to the system so they react
/// automatically to Light/Dark/Increase Contrast/Reduce Transparency.
enum Palette {
    /// Accent — defined in `Assets.xcassets/AccentColor.colorset`
    /// (indigo 6366f1 in light, 818cf8 in dark). The asset lives inside the
    /// Swift-Package resource bundle, so we look it up through
    /// `Bundle.module` rather than the main bundle.
    static let accent = Color("AccentColor", bundle: .module)

    /// Window-level backdrop. The actual chrome uses `Materials.window`.
    static let background = Color(nsColor: .windowBackgroundColor)

    /// Card / inspector backdrop used over the window material.
    static let surface = Color(nsColor: .controlBackgroundColor)

    /// Elevated surface for floating action menus and toasts.
    static let surfaceElevated = Color(nsColor: .underPageBackgroundColor)

    /// Hairline divider color, ~8% foreground.
    static let border = Color.primary.opacity(0.08)

    /// Stronger divider used in inspectors.
    static let borderStrong = Color.primary.opacity(0.14)

    /// Primary text.
    static let textPrimary = Color(nsColor: .labelColor)

    /// Secondary text — metadata, captions.
    static let textSecondary = Color(nsColor: .secondaryLabelColor)

    /// Tertiary text — disabled controls, faint hints.
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    /// Sidebar selection highlight.
    static let selectionFill = Color.accentColor.opacity(0.16)

    /// Status colors used by `StatusDot`.
    enum Status {
        static let pending = Color(nsColor: .quaternaryLabelColor)
        static let processing = Color.accentColor
        static let success = Color(nsColor: .systemGreen)
        static let failure = Color(nsColor: .systemRed)
        static let cancelled = Color(nsColor: .tertiaryLabelColor)
    }

    /// Checkerboard tiles drawn behind RGBA cutouts.
    enum Checker {
        static let light = Color(red: 0.949, green: 0.949, blue: 0.969)  // #F2F2F7
        static let dark = Color(red: 0.110, green: 0.110, blue: 0.118)   // #1C1C1E
    }
}
