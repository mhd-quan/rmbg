import SwiftUI

/// Detail surface — placeholder for now. Task #7 + #8 wire the
/// `SingleDetailView` with the before/after slider; Task #9 adds batch
/// detail. For now, the view shows job metadata so navigation can be
/// exercised.
struct DetailView: View {
    @Environment(JobStore.self) private var jobs
    @Environment(SelectionStore.self) private var selection

    var body: some View {
        Group {
            if let job = selectedJob {
                switch job.kind {
                case .single:
                    SingleDetailView(job: job)
                case .batch:
                    placeholderDetail(for: job)
                }
            } else {
                emptyState
            }
        }
        .contentMaterial()
    }

    private var selectedJob: ImageJob? {
        guard let id = selection.selectedJobID else { return nil }
        return jobs.job(for: id)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.l) {
            GlyphView<ImageGlyph>(size: 56, lineWidth: 1.2)
                .foregroundStyle(Palette.textTertiary)
            Text("Nothing selected")
                .appFont(.titleM)
                .foregroundStyle(Palette.textPrimary)
            Text("Pick a job on the left to inspect the before/after.")
                .appFont(.caption)
                .foregroundStyle(Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func placeholderDetail(for job: ImageJob) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack {
                StatusDot(status: job.status)
                Text(job.kind.displayTitle).appFont(.titleL)
                Spacer()
            }
            if let result = job.singleResult {
                Text("\(result.width) × \(result.height) · \(String(format: "%.2f s", result.durationSeconds))")
                    .appFont(.body)
                    .foregroundStyle(Palette.textSecondary)
                Text("Output: \(result.outputPath)")
                    .appFont(.monoSmall)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer()
            Text("Before/after slider lands in the next milestone.")
                .appFont(.caption)
                .foregroundStyle(Palette.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
        .padding(Spacing.xxxl)
    }
}

#Preview {
    DetailView()
        .environment(JobStore.preview())
        .environment(SelectionStore.preview())
        .frame(width: 700, height: 500)
}
