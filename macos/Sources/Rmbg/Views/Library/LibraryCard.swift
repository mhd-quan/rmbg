import SwiftUI

/// One card in the Library grid. The thumbnail reads the cutout (output)
/// when the job has completed and falls back to the original input
/// otherwise. The footer shows filename + dimensions + duration. Selection
/// is signalled by a soft accent-tinted background fill rather than a heavy
/// border stroke — closer to Photos.app / Finder column-view aesthetics.
struct LibraryCard: View {
    @Bindable var job: ImageJob
    var isSelected: Bool = false

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(job.kind.displayTitle)
                    .appFont(.body)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(job.kind.displayTitle)

                HStack(spacing: 4) {
                    StatusDot(status: job.status, diameter: 6)
                    Text(metadataString)
                        .appFont(.caption)
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.s)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isHovered ? 1.012 : 1.0)
        .shadow(color: .black.opacity(isSelected || isHovered ? 0.10 : 0.0),
                radius: isSelected || isHovered ? 8 : 0,
                x: 0,
                y: isSelected || isHovered ? 4 : 0)
        .animation(AppAnimation.snappy, value: isHovered)
        .animation(AppAnimation.snappy, value: isSelected)
        .contentShape(RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous))
        .onHover { hovering in isHovered = hovering }
    }

    // MARK: - Thumbnail composition

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            JobThumbnail(url: thumbnailURL)
                .aspectRatio(4.0 / 3.0, contentMode: .fit)

            // Top-left status chip — minimal, never blocks the image.
            if let chipLabel {
                HStack(spacing: Spacing.xs) {
                    if case .processing = job.status {
                        SpinnerGlyph(size: 9, lineWidth: 1.1)
                    } else if case .partial = job.status {
                        SpinnerGlyph(size: 9, lineWidth: 1.1)
                    } else {
                        Circle()
                            .fill(chipColor)
                            .frame(width: 6, height: 6)
                    }
                    Text(chipLabel)
                        .appFont(.caption)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, 3)
                .background(.black.opacity(0.55), in: Capsule(style: .continuous))
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: - Derived data

    private var thumbnailURL: URL? {
        if let result = job.singleResult {
            return result.previewURL ?? result.outputURL
        }
        if case .single(let url) = job.kind { return url }
        return nil
    }

    private var metadataString: String {
        if let result = job.singleResult {
            return "\(result.width) × \(result.height) · \(format(result.durationSeconds))"
        }
        switch job.status {
        case .warming: return "Warming model"
        case .processing: return "Processing"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .partial(let d, let t): return "\(d) of \(t)"
        case .pending: return "Queued"
        default: return "—"
        }
    }

    private func format(_ seconds: Double) -> String {
        if seconds < 1 { return String(format: "%.0f ms", seconds * 1000) }
        if seconds < 60 { return String(format: "%.2f s", seconds) }
        let m = Int(seconds) / 60; let s = Int(seconds) % 60
        return "\(m)m \(s)s"
    }

    private var chipLabel: String? {
        switch job.status {
        case .warming: return "Warming"
        case .processing: return "Processing"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .partial(let d, let t): return "\(d)/\(t)"
        default: return nil
        }
    }

    private var chipColor: Color {
        switch job.status {
        case .failed: return Palette.Status.failure
        case .cancelled: return Palette.Status.cancelled
        default: return Palette.accent
        }
    }

    private var secondaryColor: Color {
        switch job.status {
        case .failed: return Palette.Status.failure
        default: return Palette.textSecondary
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
            .fill(isSelected ? Palette.accent.opacity(0.10) : Color.clear)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
            .stroke(isSelected ? Palette.accent.opacity(0.55) : Palette.border,
                    lineWidth: isSelected ? 1.0 : 0.5)
    }
}

#Preview("Succeeded") {
    LibraryCard(job: ImageJob.previewSingle(named: "lighthouse.jpg"))
        .frame(width: 240)
        .padding(24)
}

#Preview("Processing") {
    LibraryCard(job: ImageJob.previewSingle(named: "robot.png",
                                            status: .processing(progress: 0.4)))
        .frame(width: 240)
        .padding(24)
}

#Preview("Failed selected") {
    LibraryCard(
        job: {
            let j = ImageJob.previewSingle(named: "ChatGPT Image May 24, 2026, 01_51_29 AM.png")
            j.status = .failed(message: "Job cancelled.")
            return j
        }(),
        isSelected: true
    )
    .frame(width: 240)
    .padding(24)
}
