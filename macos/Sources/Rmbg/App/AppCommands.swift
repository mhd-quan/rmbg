import AppKit
import SwiftUI

/// Global menu commands. The struct is constructed by `RmbgApp` with
/// references to the live stores so each menu item can drive them
/// directly without needing FocusedValue plumbing.
struct AppCommands: Commands {
    let jobStore: JobStore
    let selection: SelectionStore
    let settings: SettingsStore
    let banners: BannerCenter
    let recents: RecentsStore

    var body: some Commands {
        // File menu
        CommandGroup(replacing: .newItem) {
            Button("Open Image…") { openImage() }
                .keyboardShortcut("o", modifiers: [.command])

            Button("Open Folder…") { openFolder() }
                .keyboardShortcut("o", modifiers: [.command, .shift])
        }

        CommandGroup(after: .saveItem) {
            Divider()
            Button("Export") { exportSelected(useDefaults: true) }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(!hasSelection)
            Button("Export…") { exportSelected(useDefaults: false) }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!hasSelection)
            Button("Reveal in Finder") { revealSelected() }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!hasSelection)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Remove from Library") { removeSelected() }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(!hasSelection)
            Button("Cancel Job") { cancelSelected() }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!hasRunningSelection)
        }

        // View menu
        CommandMenu("View") {
            Button("Library") { selection.select(section: .library) }
                .keyboardShortcut("1", modifiers: [.command])
            Button("Batch Queue") { selection.select(section: .batch) }
                .keyboardShortcut("2", modifiers: [.command])
            Button("Recents") { selection.select(section: .recents) }
                .keyboardShortcut("3", modifiers: [.command])
            Divider()
            Button(selection.sidebarVisible ? "Hide Sidebar" : "Show Sidebar") {
                selection.toggleSidebar()
            }
            .keyboardShortcut("[", modifiers: [.command])
        }
    }

    // MARK: - Selection helpers

    private var selectedJob: ImageJob? {
        guard let id = selection.selectedJobID else { return nil }
        return jobStore.job(for: id)
    }

    private var hasSelection: Bool { selectedJob != nil }

    private var hasRunningSelection: Bool {
        guard let job = selectedJob else { return false }
        return job.status.isRunning
    }

    // MARK: - Actions

    private func openImage() {
        let panel = NSOpenPanel()
        panel.title = "Open image"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let urls = panel.urls.filter { $0.isSupportedImageExtension }
            guard !urls.isEmpty else { return }
            let job = jobStore.ingest(urls)
            selection.select(section: urls.count == 1 ? .library : .batch)
            if let job { selection.select(jobID: job.id) }
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.title = "Open folder of images"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let folder = panel.url {
            let expanded = DropTargetModifier.expandToImageURLs([folder])
            guard !expanded.isEmpty else {
                banners.post(.warning, "No images found", "The selected folder doesn't contain any supported images.")
                return
            }
            let job = jobStore.ingest(expanded)
            selection.select(section: .batch)
            if let job { selection.select(jobID: job.id) }
        }
    }

    private func revealSelected() {
        guard let job = selectedJob else { return }
        if let result = job.singleResult {
            FileManager.reveal(result.outputURL)
        } else if case .single(let url) = job.kind {
            FileManager.reveal(url)
        }
    }

    private func exportSelected(useDefaults: Bool) {
        guard let job = selectedJob, let result = job.singleResult else { return }
        if useDefaults {
            // Default export = open the output file (already saved on disk).
            banners.post(.success, "Saved", URL(fileURLWithPath: result.outputPath).lastPathComponent, autoDismiss: 3)
            if settings.revealAfterExport {
                FileManager.reveal(result.outputURL)
            }
            return
        }
        let panel = NSSavePanel()
        panel.title = "Export cutout"
        panel.nameFieldStringValue = URL(fileURLWithPath: result.outputPath).lastPathComponent
        panel.allowedContentTypes = [.png, .jpeg, .webP, .tiff]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let destination = panel.url {
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: result.outputURL, to: destination)
                banners.post(.success, "Exported", destination.lastPathComponent)
                if settings.revealAfterExport { FileManager.reveal(destination) }
            } catch {
                banners.post(.error, "Export failed", error.localizedDescription)
            }
        }
    }

    private func removeSelected() {
        guard let job = selectedJob else { return }
        jobStore.remove(job)
        selection.select(jobID: nil)
    }

    private func cancelSelected() {
        guard let job = selectedJob else { return }
        jobStore.cancel(job)
    }
}
