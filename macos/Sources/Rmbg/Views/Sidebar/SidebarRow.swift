import SwiftUI

/// Single navigable row in the sidebar. Renders a glyph, the section title,
/// and an optional count badge. Selection state is driven externally so the
/// sidebar can host this in either a `List` (selection ring from system) or
/// a custom `VStack` (selection drawn locally).
struct SidebarRow<G: Glyph>: View {
    let glyph: G.Type
    let title: String
    var count: Int = 0
    var isSelected: Bool = false
    var isHovered: Bool = false

    var body: some View {
        HStack(spacing: Spacing.m) {
            GlyphView<G>(size: 16, lineWidth: 1.1)
                .foregroundStyle(glyphTint)
                .frame(width: 18, height: 18)

            Text(title)
                .appFont(isSelected ? .bodyEmphasized : .body)
                .foregroundStyle(textTint)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: Spacing.s)

            CountBadge(
                count: count,
                tint: isSelected ? Palette.accent : Palette.textTertiary
            )
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        .background(rowBackground)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Spacing.Radius.s, style: .continuous)
            .fill(backgroundFill)
    }

    private var backgroundFill: Color {
        if isSelected { return Palette.accent.opacity(0.18) }
        if isHovered { return Color.primary.opacity(0.06) }
        return .clear
    }

    private var glyphTint: Color {
        isSelected ? Palette.accent : Palette.textSecondary
    }

    private var textTint: Color {
        isSelected ? Palette.textPrimary : Palette.textPrimary.opacity(0.92)
    }
}

#Preview {
    VStack(spacing: 4) {
        SidebarRow(glyph: LibraryGlyph.self, title: "Library", count: 4, isSelected: true)
        SidebarRow(glyph: BatchGlyph.self, title: "Batch Queue", count: 12)
        SidebarRow(glyph: RecentGlyph.self, title: "Recents", isHovered: true)
    }
    .frame(width: 240)
    .padding(8)
}
