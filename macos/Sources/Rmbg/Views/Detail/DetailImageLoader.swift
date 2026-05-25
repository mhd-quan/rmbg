import AppKit
import Foundation
import SwiftUI

/// Loads the original image and the cutout from disk so the before/after
/// surface has both. Reads `Data` on a background task — `Data` is
/// `Sendable`, unlike `NSImage` — and constructs `NSImage` back on the main
/// actor. Hi-res images (often >5 MB) decode synchronously on first draw,
/// which is acceptable here since the work is initiated by an explicit
/// selection.
@MainActor
@Observable
final class DetailImageLoader {
    var beforeImage: NSImage?
    var afterImage: NSImage?
    var isLoading: Bool = false

    func load(for job: ImageJob) async {
        isLoading = true
        defer { isLoading = false }

        let beforeURL: URL?
        switch job.kind {
        case .single(let url): beforeURL = url
        case .batch: beforeURL = nil
        }
        let afterURL = job.singleResult?.outputURL

        async let beforeData = Self.readData(at: beforeURL)
        async let afterData = Self.readData(at: afterURL)

        let (before, after) = await (beforeData, afterData)
        beforeImage = before.flatMap { NSImage(data: $0) }
        afterImage = after.flatMap { NSImage(data: $0) }
    }

    /// Read file bytes off the main actor. Returns nil on any failure.
    nonisolated private static func readData(at url: URL?) async -> Data? {
        guard let url else { return nil }
        return await Task.detached(priority: .userInitiated) {
            try? Data(contentsOf: url)
        }.value
    }
}
