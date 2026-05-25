import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// View modifier that turns its host into a global drop target for image
/// files and folders. Multi-image drops route through `JobStore.ingest`
/// which dispatches to either `startSingle` or `startBatch`. While a drag
/// is over the window we overlay the project's `DashedDropOverlay` and
/// trigger the `dragEnter` haptic on entry.
struct DropTargetModifier: ViewModifier {
    @Environment(JobStore.self) private var jobs
    @Environment(SelectionStore.self) private var selection
    @State private var isTargeted = false
    @State private var acceptedTick: Int = 0

    func body(content: Content) -> some View {
        content
            .dropDestination(for: URL.self) { urls, _ in
                let expanded = Self.expandToImageURLs(urls)
                guard !expanded.isEmpty else { return false }
                let job = jobs.ingest(expanded)
                if let job {
                    selection.select(section: expanded.count == 1 ? .library : .batch)
                    selection.select(jobID: job.id)
                }
                acceptedTick &+= 1
                return true
            } isTargeted: { hovering in
                isTargeted = hovering
            }
            .overlay {
                if isTargeted {
                    DashedDropOverlay()
                        .transition(.opacity)
                }
            }
            .animation(AppAnimation.snappy, value: isTargeted)
            .appHaptic(.dragEnter, trigger: isTargeted)
            .appHaptic(.dropAccept, trigger: acceptedTick)
    }

    /// Flatten any folders in the drop list into their contained images.
    /// Files with unsupported extensions are silently skipped.
    static func expandToImageURLs(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                if let enumerator = fm.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let item as URL in enumerator where item.isSupportedImageExtension {
                        result.append(item)
                    }
                }
            } else if url.isSupportedImageExtension {
                result.append(url)
            }
        }
        return result
    }
}

extension View {
    /// Make the view act as a global drop target. See `DropTargetModifier`
    /// for details.
    func dropTargetForImages() -> some View {
        modifier(DropTargetModifier())
    }
}
