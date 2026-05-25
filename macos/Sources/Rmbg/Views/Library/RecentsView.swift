import SwiftUI

/// Recents section — pulls from `RecentsStore` (persisted history). Reuses
/// the same `LibraryCard`/`LibraryGrid` aesthetic but reconstructs a
/// throwaway `ImageJob` from each `BackendResult` so cards render identically.
struct RecentsView: View {
    @Environment(RecentsStore.self) private var recents

    var body: some View {
        VStack(spacing: 0) {
            ContentHeader(title: "Recents", subtitle: subtitle) {
                if !recents.recents.isEmpty {
                    Button("Clear") { recents.clear() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            Group {
                if recents.recents.isEmpty {
                    VStack(spacing: Spacing.l) {
                        GlyphView<RecentGlyph>(size: 48, lineWidth: 1.3)
                            .foregroundStyle(Palette.textTertiary)
                        Text("No recent removals")
                            .appFont(.titleM)
                            .foregroundStyle(Palette.textPrimary)
                        Text("Finished jobs from previous sessions will appear here.")
                            .appFont(.caption)
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LibraryGrid(jobs: jobsFromRecents)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentMaterial()
    }

    private var subtitle: String {
        let count = recents.recents.count
        if count == 0 { return "Persisted across sessions." }
        if count == 1 { return "1 saved cutout" }
        return "\(count) saved cutouts"
    }

    private var jobsFromRecents: [ImageJob] {
        recents.recents.map { result in
            ImageJob(
                kind: .single(result.inputURL),
                status: .succeeded,
                exportRequest: .defaultRequest(),
                singleResult: result
            )
        }
    }
}

#Preview {
    RecentsView()
        .environment(RecentsStore.preview())
        .environment(SelectionStore.preview())
        .frame(width: 800, height: 500)
}
