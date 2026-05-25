import SwiftUI

/// Top-level header for a batch job in the Batch Queue. Shows the aggregate
/// progress, a 2pt hairline bar, and contextual actions (cancel, retry).
struct BatchAggregateHeader: View {
    @Bindable var job: ImageJob
    @Environment(JobStore.self) private var jobs

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .appFont(.titleM)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text(progressLabel)
                    .appFont(.monoSmall)
                    .foregroundStyle(Palette.textSecondary)
            }

            ProgressBarHairline(progress: progressValue, height: 3)

            HStack(spacing: Spacing.m) {
                StatusDot(status: job.status)
                Text(statusDescription)
                    .appFont(.caption)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                actionButtons
            }
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous)
                .fill(Palette.surface.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        )
    }

    private var title: String {
        if case .batch(let urls) = job.kind {
            return urls.first?.deletingLastPathComponent().lastPathComponent ?? "Batch"
        }
        return job.kind.displayTitle
    }

    private var progressLabel: String {
        switch job.status {
        case .partial(let d, let t): return "\(d) / \(t)"
        case .succeeded:
            if let s = job.batchSummary { return "\(s.processed) / \(s.total)" }
            return ""
        case .failed:
            if let s = job.batchSummary { return "\(s.processed) / \(s.total) · \(s.failed) failed" }
            return "failed"
        case .cancelled: return "cancelled"
        default: return ""
        }
    }

    private var progressValue: Double {
        switch job.status {
        case .partial(let d, let t): return t == 0 ? 0 : Double(d) / Double(t)
        case .succeeded: return 1
        case .failed:
            if let s = job.batchSummary, s.total > 0 {
                return Double(s.processed + s.failed) / Double(s.total)
            }
            return 1
        default: return 0
        }
    }

    private var statusDescription: String {
        switch job.status {
        case .pending: return "Queued"
        case .warming: return "Warming model"
        case .processing: return "Processing"
        case .partial(let d, let t):
            let remaining = t - d
            return remaining > 0 ? "\(remaining) remaining" : "Finalizing"
        case .succeeded:
            if let s = job.batchSummary {
                return "Done in \(formatDuration(s.durationSeconds))"
            }
            return "Done"
        case .failed(let m): return m
        case .cancelled: return "Stopped by you"
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 { return String(format: "%.1f s", seconds) }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
    }

    @ViewBuilder
    private var actionButtons: some View {
        if job.status.isRunning {
            Button("Stop") { jobs.cancel(job) }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .appFont(.callout)
        }
        if case .failed = job.status {
            Button("Retry") { jobs.retry(job) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        Menu {
            Button("Remove") { jobs.remove(job) }
        } label: {
            GlyphView<MoreGlyph>(size: 14, lineWidth: 1)
                .padding(.horizontal, 4)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 28)
    }
}
