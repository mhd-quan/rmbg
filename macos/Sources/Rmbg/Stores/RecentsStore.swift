import Foundation
import Observation

/// A bounded ring of the most recent successful single-image jobs. Persists
/// to `~/Library/Application Support/Rmbg/recents.json` so the Library tab
/// repopulates on relaunch.
@MainActor
@Observable
final class RecentsStore {
    private(set) var recents: [BackendResult] = []

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let maxEntries: Int

    init(fileURL: URL? = nil, maxEntries: Int = 50) {
        let resolved = fileURL ?? Self.defaultFileURL
        self.fileURL = resolved
        self.maxEntries = maxEntries
        self.recents = Self.loadFromDisk(url: resolved)
    }

    func add(_ result: BackendResult) {
        recents.removeAll { $0.outputPath == result.outputPath }
        recents.insert(result, at: 0)
        if recents.count > maxEntries {
            recents.removeLast(recents.count - maxEntries)
        }
        persistToDisk()
    }

    func remove(matching outputPath: String) {
        recents.removeAll { $0.outputPath == outputPath }
        persistToDisk()
    }

    func clear() {
        recents.removeAll()
        persistToDisk()
    }

    // MARK: - Disk I/O

    nonisolated static let defaultFileURL: URL = {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("Rmbg", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("recents.json")
    }()

    nonisolated private static func loadFromDisk(url: URL) -> [BackendResult] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode([BackendResult].self, from: data)) ?? []
    }

    private func persistToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(recents) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

extension RecentsStore {
    static func preview(seeded: Bool = true) -> RecentsStore {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("rmbg-preview-\(UUID().uuidString)/recents.json")
        try? FileManager.default.createDirectory(at: tmp.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        let store = RecentsStore(fileURL: tmp)
        if seeded {
            store.recents = [
                .preview(name: "lighthouse.jpg"),
                .preview(name: "robot.png", duration: 0.92),
                .preview(name: "sunset.jpg", duration: 2.13),
            ]
        }
        return store
    }
}
