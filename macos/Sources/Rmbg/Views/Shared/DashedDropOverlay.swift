import SwiftUI

/// Full-window overlay shown while a drag operation is targeting the
/// application. Inspired by Things 3's drop affordance: a soft inset border
/// with a centered glyph + label, never a heavy modal block.
struct DashedDropOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous)
                .strokeBorder(
                    Palette.accent.opacity(0.65),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 5])
                )
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous)
                        .fill(Palette.accent.opacity(0.06))
                        .padding(Spacing.xl)
                )

            VStack(spacing: Spacing.l) {
                GlyphView<DropZoneGlyph>(size: 56, lineWidth: 1.4)
                    .foregroundStyle(Palette.accent)
                Text("Drop to remove background")
                    .appFont(.titleM)
                    .foregroundStyle(Palette.textPrimary)
                Text("PNG · JPG · HEIC · WebP · TIFF")
                    .appFont(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    DashedDropOverlay()
        .frame(width: 800, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
}
