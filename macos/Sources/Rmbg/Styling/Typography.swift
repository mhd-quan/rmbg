import SwiftUI

/// Typographic tokens. Sizes, weights, and kerning calibrated for the
/// hierarchy described in the design plan. Use `view.appFont(.titleL)` to
/// apply a complete style in one modifier.
enum AppFont: Hashable {
    case titleXL          // 36 semibold, kerning -0.5  — empty-state headings
    case titleL           // 24 semibold, kerning -0.3  — section headers
    case titleM           // 17 semibold, kerning -0.15 — settings tab titles
    case body             // 13 regular, kerning 0      — default reading size
    case bodyEmphasized   // 13 semibold, kerning 0     — selected sidebar row
    case bodySecondary    // 13 regular, kerning 0      — secondary copy
    case caption          // 11 medium uppercase, kerning 0.6 — section labels
    case callout          // 12 medium, kerning 0.1     — buttons, pills
    case monoSmall        // 11 monospaced tabular      — counts, timings

    var size: CGFloat {
        switch self {
        case .titleXL: return 36
        case .titleL: return 24
        case .titleM: return 17
        case .body, .bodyEmphasized, .bodySecondary: return 13
        case .caption: return 11
        case .callout: return 12
        case .monoSmall: return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .titleXL, .titleL, .titleM, .bodyEmphasized: return .semibold
        case .body, .bodySecondary: return .regular
        case .caption, .callout: return .medium
        case .monoSmall: return .regular
        }
    }

    var kerning: CGFloat {
        switch self {
        case .titleXL: return -0.5
        case .titleL: return -0.3
        case .titleM: return -0.15
        case .body, .bodyEmphasized, .bodySecondary: return 0
        case .caption: return 0.6
        case .callout: return 0.1
        case .monoSmall: return 0
        }
    }

    var design: Font.Design {
        if case .monoSmall = self { return .monospaced }
        return .default
    }

    var font: Font {
        if case .monoSmall = self {
            return .system(size: size, weight: weight, design: .monospaced)
                .monospacedDigit()
        }
        return .system(size: size, weight: weight, design: design)
    }

    var isUppercased: Bool {
        if case .caption = self { return true }
        return false
    }
}

extension View {
    /// Apply a complete `AppFont` token (font + kerning + casing transform).
    func appFont(_ token: AppFont) -> some View {
        modifier(AppFontModifier(token: token))
    }
}

private struct AppFontModifier: ViewModifier {
    let token: AppFont

    func body(content: Content) -> some View {
        content
            .font(token.font)
            .kerning(token.kerning)
            .textCase(token.isUppercased ? .uppercase : nil)
    }
}
