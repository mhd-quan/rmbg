import Foundation
import Observation

/// Persistent app preferences, backed by `UserDefaults`. Each property writes
/// through to defaults on `didSet`. The `@Observable` macro broadcasts
/// changes to any SwiftUI view that read the property.
@MainActor
@Observable
final class SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults

    // MARK: Backend

    var backendExecutableURL: URL? {
        didSet { save(backendExecutableURL?.path, forKey: Keys.backendExecutable) }
    }

    var device: DevicePreference {
        didSet { save(device.rawValue, forKey: Keys.device) }
    }

    var hfHomeOverride: URL? {
        didSet { save(hfHomeOverride?.path, forKey: Keys.hfHome) }
    }

    // MARK: Output

    var outputDirectory: URL {
        didSet { save(outputDirectory.path, forKey: Keys.outputDir) }
    }

    var outputFormat: OutputFormat {
        didSet { save(outputFormat.rawValue, forKey: Keys.outputFormat) }
    }

    var backgroundColor: String {
        didSet { save(backgroundColor, forKey: Keys.backgroundColor) }
    }

    var saveAlphaMask: Bool {
        didSet { save(saveAlphaMask, forKey: Keys.saveAlphaMask) }
    }

    var savePreview: Bool {
        didSet { save(savePreview, forKey: Keys.savePreview) }
    }

    var overwriteExisting: Bool {
        didSet { save(overwriteExisting, forKey: Keys.overwrite) }
    }

    var batchRecursive: Bool {
        didSet { save(batchRecursive, forKey: Keys.batchRecursive) }
    }

    // MARK: UX

    var hapticsEnabled: Bool {
        didSet { save(hapticsEnabled, forKey: Keys.haptics) }
    }

    var revealAfterExport: Bool {
        didSet { save(revealAfterExport, forKey: Keys.revealAfterExport) }
    }

    // MARK: -

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.backendExecutableURL = (defaults.string(forKey: Keys.backendExecutable))
            .map { URL(fileURLWithPath: $0) }
        // Default to CPU because Apple's MPS backend exhausts the unified
        // memory limit on Intel Macs and some integrated GPUs for RMBG-2.0
        // (which needs ~5 GB at 1024×1024). CPU is slower but always works.
        // Users can opt into MPS/CUDA from Settings → Backend.
        self.device = DevicePreference(rawValue: defaults.string(forKey: Keys.device) ?? "cpu") ?? .cpu
        self.hfHomeOverride = defaults.string(forKey: Keys.hfHome).map { URL(fileURLWithPath: $0) }

        self.outputDirectory = defaults.string(forKey: Keys.outputDir)
            .map { URL(fileURLWithPath: $0) } ?? ExportRequest.defaultOutputDirectory
        self.outputFormat = OutputFormat(rawValue: defaults.string(forKey: Keys.outputFormat) ?? "png") ?? .png
        self.backgroundColor = defaults.string(forKey: Keys.backgroundColor) ?? "#ffffff"
        self.saveAlphaMask = defaults.bool(forKey: Keys.saveAlphaMask)
        self.savePreview = defaults.object(forKey: Keys.savePreview) as? Bool ?? true
        self.overwriteExisting = defaults.bool(forKey: Keys.overwrite)
        self.batchRecursive = defaults.bool(forKey: Keys.batchRecursive)

        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.revealAfterExport = defaults.bool(forKey: Keys.revealAfterExport)
    }

    /// Convert the current settings into the export request that gets sent to
    /// the backend for new jobs.
    func currentExportRequest() -> ExportRequest {
        ExportRequest(
            outputDirectory: outputDirectory,
            suffix: "_rmbg",
            outputFormat: outputFormat,
            backgroundColor: outputFormat.supportsAlpha ? nil : backgroundColor,
            overwrite: overwriteExisting,
            saveAlphaMask: saveAlphaMask,
            savePreview: savePreview,
            previewBackground: "#f2f2f7",
            recursive: batchRecursive,
            device: device
        )
    }

    // MARK: - Persistence helpers

    private func save<T>(_ value: T?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private enum Keys {
        static let backendExecutable = "RmbgBackendExecutable"
        static let device = "RmbgDevice"
        static let hfHome = "RmbgHFHome"
        static let outputDir = "RmbgOutputDir"
        static let outputFormat = "RmbgOutputFormat"
        static let backgroundColor = "RmbgBackgroundColor"
        static let saveAlphaMask = "RmbgSaveAlphaMask"
        static let savePreview = "RmbgSavePreview"
        static let overwrite = "RmbgOverwrite"
        static let batchRecursive = "RmbgBatchRecursive"
        static let haptics = "RmbgHaptics"
        static let revealAfterExport = "RmbgRevealAfterExport"
    }
}

extension SettingsStore {
    /// Sandboxed defaults so previews don't read or write the real `.plist`.
    static func preview() -> SettingsStore {
        let suite = "rmbg.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        return SettingsStore(defaults: defaults)
    }
}
