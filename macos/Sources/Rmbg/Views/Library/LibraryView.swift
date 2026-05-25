import AppKit
import SwiftUI

/// Library content area. Owns the empty/non-empty switch and the open-file
/// affordance. Selecting a card drives `SelectionStore.selectedJobID`, which
/// the `DetailView` picks up to render the before/after.
struct LibraryView: View {
    @Environment(JobStore.self) private var jobs
    @Environment(SelectionStore.self) private var selection

    var body: some View {
        VStack(spacing: 0) {
            ContentHeader(title: "Library", subtitle: subtitle) {
                Button { openPanel() } label: {
                    HStack(spacing: 4) {
                        GlyphView<FolderGlyph>(size: 12, lineWidth: 1)
                        Text("Open…").appFont(.callout)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .keyboardShortcut("o", modifiers: [.command])
            }

            Group {
                if jobs.libraryJobs.isEmpty {
                    EmptyDropZone(onPick: openPanel)
                        .transition(.opacity)
                } else {
                    LibraryGrid(jobs: jobs.libraryJobs)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(AppAnimation.slowFade, value: jobs.libraryJobs.isEmpty)
        }
        .contentMaterial()
    }

    private var subtitle: String {
        let count = jobs.libraryJobs.count
        if count == 0 { return "Drop an image to remove its background." }
        if count == 1 { return "1 image" }
        return "\(count) images"
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = "Open"
        if panel.runModal() == .OK {
            let urls = panel.urls.filter { $0.isSupportedImageExtension }
            guard !urls.isEmpty else { return }
            let job = jobs.ingest(urls)
            selection.select(section: urls.count == 1 ? .library : .batch)
            if let job { selection.select(jobID: job.id) }
        }
    }
}
