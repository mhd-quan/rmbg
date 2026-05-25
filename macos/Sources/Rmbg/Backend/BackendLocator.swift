import Foundation

/// Resolves the on-disk path to the `rmbg-backend` executable. Order of
/// preference:
///
/// 1. `SettingsStore.backendExecutableURL` if the user has chosen one in
///    Settings → Backend.
/// 2. `Info.plist`'s `RmbgDevRepoRoot` joined with `.venv/bin/rmbg-backend`.
///    This lets the dev build always point at the right venv.
/// 3. `~/Documents/rmbg/.venv/bin/rmbg-backend` — convention path.
/// 4. The first hit of `which rmbg-backend` on `$PATH`.
@MainActor
final class BackendLocator {
    private let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
    }

    /// Resolves the executable URL. Throws `BackendError.notFound` if no
    /// candidate is found. May spawn a short-lived `which` subprocess.
    func resolve() async throws -> URL {
        if let url = settings.backendExecutableURL, isExecutable(url) {
            return url
        }

        if let root = Bundle.main.object(forInfoDictionaryKey: "RmbgDevRepoRoot") as? String {
            let url = URL(fileURLWithPath: root)
                .appendingPathComponent(".venv/bin/rmbg-backend")
            if isExecutable(url) { return url }
        }

        let documentsHome = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/rmbg/.venv/bin/rmbg-backend")
        if isExecutable(documentsHome) { return documentsHome }

        if let url = await Task.detached(priority: .utility, operation: Self.whichBackend).value {
            return url
        }

        throw BackendError.notFound
    }

    /// Synchronously probe for the executable without spawning `which`. Used
    /// at app launch to populate `BackendHealthStore.backendExecutable`
    /// without paying for a subprocess. Returns `nil` if not found.
    func probeWithoutWhich() -> URL? {
        if let url = settings.backendExecutableURL, isExecutable(url) { return url }
        if let root = Bundle.main.object(forInfoDictionaryKey: "RmbgDevRepoRoot") as? String {
            let url = URL(fileURLWithPath: root)
                .appendingPathComponent(".venv/bin/rmbg-backend")
            if isExecutable(url) { return url }
        }
        let documentsHome = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/rmbg/.venv/bin/rmbg-backend")
        if isExecutable(documentsHome) { return documentsHome }
        return nil
    }

    private func isExecutable(_ url: URL) -> Bool {
        let fm = FileManager.default
        return fm.isExecutableFile(atPath: url.path)
    }

    /// Runs `/usr/bin/env which rmbg-backend` off the main actor. Returns the
    /// resolved URL or nil on any failure.
    @Sendable
    nonisolated private static func whichBackend() -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "rmbg-backend"]
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let data = try? stdout.fileHandleForReading.readToEnd(),
              let str = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !str.isEmpty
        else { return nil }
        return URL(fileURLWithPath: str)
    }
}
