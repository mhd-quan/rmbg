import SwiftUI

/// Custom hand-rolled sidebar. We deliberately avoid `.listStyle(.sidebar)`
/// because it imposes a system row template that hides our custom row text
/// at the chosen sidebar width — see the report in the project history. By
/// rendering rows directly via `Button` + `SidebarRow` we get full control
/// of selection, hover, and animation.
struct SidebarView: View {
    @Environment(JobStore.self) private var jobs
    @Environment(RecentsStore.self) private var recents
    @Environment(SelectionStore.self) private var selection

    @State private var hoveredSection: AppSection?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SidebarSectionHeader(title: "Work")
                    sidebarButton(
                        section: .library,
                        glyph: LibraryGlyph.self,
                        title: "Library",
                        count: jobs.libraryJobs.count
                    )
                    sidebarButton(
                        section: .batch,
                        glyph: BatchGlyph.self,
                        title: "Batch Queue",
                        count: jobs.batchJobs.count
                    )

                    SidebarSectionHeader(title: "History")
                    sidebarButton(
                        section: .recents,
                        glyph: RecentGlyph.self,
                        title: "Recents",
                        count: recents.recents.count
                    )
                }
                .padding(.horizontal, Spacing.s)
                .padding(.top, Spacing.m)
            }
            .scrollIndicators(.never)

            SidebarFooter()
                .padding(.horizontal, Spacing.s)
                .padding(.bottom, Spacing.m)
        }
        .frame(minWidth: 200)
        .sidebarMaterial()
    }

    @ViewBuilder
    private func sidebarButton<G: Glyph>(
        section: AppSection,
        glyph: G.Type,
        title: String,
        count: Int
    ) -> some View {
        Button {
            selection.select(section: section)
        } label: {
            SidebarRow(
                glyph: G.self,
                title: title,
                count: count,
                isSelected: selection.section == section,
                isHovered: hoveredSection == section
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                hoveredSection = hovering ? section : nil
            }
        }
        .appHaptic(.selectionChange, trigger: selection.section)
    }
}

#Preview {
    SidebarView()
        .environment(JobStore.preview())
        .environment(RecentsStore.preview())
        .environment(SelectionStore.preview())
        .environment(BackendHealthStore.preview())
        .environment(SettingsStore.preview())
        .frame(width: 240, height: 600)
}
