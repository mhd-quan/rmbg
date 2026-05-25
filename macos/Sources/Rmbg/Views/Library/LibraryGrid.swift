import SwiftUI

/// Adaptive grid of library cards. Selection drives `SelectionStore`. Empty
/// state is handled by `LibraryView`; this view assumes `jobs` is non-empty.
struct LibraryGrid: View {
    let jobs: [ImageJob]
    @Environment(SelectionStore.self) private var selection

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 320),
                                    spacing: Spacing.xl)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns,
                      alignment: .leading,
                      spacing: Spacing.xl) {
                ForEach(jobs) { job in
                    LibraryCard(job: job, isSelected: selection.selectedJobID == job.id)
                        .onTapGesture {
                            selection.select(jobID: job.id)
                        }
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
    }
}
