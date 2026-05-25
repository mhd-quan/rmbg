import SwiftUI

/// Replaces the placeholder batch view. Vertical scroll surface with one
/// aggregate header card per active batch, followed by a list of items as
/// they stream in. `BatchSummary.Item`s are sourced from `job.batchResults`
/// which is appended on every `progress` line.
struct BatchQueueView: View {
    @Environment(JobStore.self) private var jobs
    @Environment(SelectionStore.self) private var selection

    var body: some View {
        VStack(spacing: 0) {
            ContentHeader(title: "Batch Queue", subtitle: subtitle)

            Group {
                if jobs.batchJobs.isEmpty {
                    BatchEmptyState()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                            ForEach(jobs.batchJobs) { job in
                                VStack(alignment: .leading, spacing: Spacing.m) {
                                    BatchAggregateHeader(job: job)
                                    ForEach(job.batchResults) { item in
                                        BatchRow(item: item)
                                            .onTapGesture {
                                                selection.select(jobID: job.id)
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.xl)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentMaterial()
    }

    private var subtitle: String {
        let active = jobs.batchJobs.filter { $0.status.isRunning }.count
        let total = jobs.batchJobs.count
        if total == 0 { return "Drop a folder, or drop multiple images at once." }
        if active == 0 { return "\(total) batch\(total == 1 ? "" : "es")" }
        return "\(active) running"
    }
}

/// Empty state for the batch queue.
struct BatchEmptyState: View {
    var body: some View {
        VStack(spacing: Spacing.l) {
            GlyphView<BatchGlyph>(size: 48, lineWidth: 1.3)
                .foregroundStyle(Palette.textTertiary)
            Text("Batch queue is empty")
                .appFont(.titleM)
                .foregroundStyle(Palette.textPrimary)
            Text("Drop a folder, or drop multiple images at once.")
                .appFont(.caption)
                .foregroundStyle(Palette.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BatchQueueView()
        .environment(JobStore.preview())
        .environment(SelectionStore.preview())
        .frame(width: 900, height: 600)
}
