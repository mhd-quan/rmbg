import AppKit
import Foundation

extension FileManager {
    /// Reveal a single file in Finder with the row selected.
    @MainActor
    static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
