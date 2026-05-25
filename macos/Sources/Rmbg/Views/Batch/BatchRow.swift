import SwiftUI

/// One image inside a batch. Shows the per-item status dot, filename, a
/// hairline progress bar if mid-flight, and per-item actions on hover.
struct BatchRow: View {
    let item: BatchSummary.Item
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.m) {
            statusDot
            VStack(alignment: .leading, spacing: 2) {
                Text(item.inputURL.lastPathComponent)
                    .appFont(.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(secondaryLine)
                    .appFont(.caption)
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.m)
            if isHovered, item.succeeded {
                Button {
                    if let result = item.result {
                        FileManager.reveal(result.outputURL)
                    }
                } label: {
                    GlyphView<RevealGlyph>(size: 14, lineWidth: 1)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Spacing.Radius.s, style: .continuous)
                .fill(isHovered ? Palette.surface.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(AppAnimation.snappy) { isHovered = hovering }
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
    }

    private var dotColor: Color {
        if item.error != nil { return Palette.Status.failure }
        if item.result != nil { return Palette.Status.success }
        return Palette.Status.pending
    }

    private var secondaryLine: String {
        if let error = item.error { return error }
        if let result = item.result {
            return "\(result.width) × \(result.height) · \(String(format: "%.2f s", result.durationSeconds))"
        }
        return "—"
    }

    private var secondaryColor: Color {
        item.error != nil ? Palette.Status.failure : Palette.textSecondary
    }
}
