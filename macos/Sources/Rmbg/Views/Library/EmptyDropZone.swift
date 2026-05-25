import SwiftUI

/// Large, centered drop affordance shown when the library has no jobs. The
/// design borrows from Things 3's empty list: heavy negative space, one
/// strong call-to-action, no toolbar competing with the message.
struct EmptyDropZone: View {
    var onPick: () -> Void = {}

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.Radius.xl, style: .continuous)
                    .strokeBorder(
                        Palette.border,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 6])
                    )
                    .frame(width: 360, height: 220)
                VStack(spacing: Spacing.m) {
                    GlyphView<DropZoneGlyph>(size: 56, lineWidth: 1.5)
                        .foregroundStyle(Palette.textSecondary)
                    Text("Drop images to begin")
                        .appFont(.titleM)
                        .foregroundStyle(Palette.textPrimary)
                    Text("PNG · JPG · HEIC · WebP · TIFF")
                        .appFont(.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }

            Button(action: onPick) {
                HStack(spacing: Spacing.s) {
                    GlyphView<FolderGlyph>(size: 14, lineWidth: 1.1)
                    Text("Choose an image…")
                        .appFont(.callout)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s + 1)
                .background(Capsule(style: .continuous).fill(Palette.accent.opacity(0.12)))
                .overlay(Capsule(style: .continuous).stroke(Palette.accent.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
            .keyboardShortcut("o", modifiers: [.command])

            VStack(spacing: 4) {
                Text("Or drag & drop anywhere")
                    .appFont(.caption)
                    .foregroundStyle(Palette.textTertiary)
                Text("⌘O  ·  ⌘⇧O  for a folder")
                    .appFont(.monoSmall)
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.top, Spacing.s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyDropZone()
        .frame(width: 800, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
}
