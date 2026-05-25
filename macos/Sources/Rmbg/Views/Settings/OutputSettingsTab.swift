import AppKit
import SwiftUI

/// Output tab. Controls how processed images are written to disk.
struct OutputSettingsTab: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Destination") {
                LabeledContent("Folder") {
                    HStack(spacing: Spacing.s) {
                        Text(settings.outputDirectory.path)
                            .appFont(.body)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                        Button("Browse…") { pickFolder() }
                            .controlSize(.small)
                    }
                }
                Toggle("Overwrite existing files", isOn: $settings.overwriteExisting)
                    .help("If off, a numbered suffix is appended (e.g. _1, _2).")
                Toggle("Recurse into sub-folders for batches", isOn: $settings.batchRecursive)
            }

            Section("Format") {
                Picker("Format", selection: $settings.outputFormat) {
                    ForEach(OutputFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                if !settings.outputFormat.supportsAlpha {
                    LabeledContent("Background") {
                        ColorPicker("", selection: backgroundColorBinding, supportsOpacity: false)
                            .labelsHidden()
                    }
                    .transition(.opacity)
                }
            }
            .animation(AppAnimation.snappy, value: settings.outputFormat)

            Section("Extras") {
                Toggle("Save alpha mask", isOn: $settings.saveAlphaMask)
                    .help("Saves a grayscale PNG of the alpha channel next to the cutout.")
                Toggle("Save side-by-side preview", isOn: $settings.savePreview)
                    .help("Saves a JPEG that places the original and the cutout side-by-side.")
            }
        }
        .formStyle(.grouped)
        .padding(Spacing.l)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose output folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = settings.outputDirectory
        if panel.runModal() == .OK, let url = panel.url {
            settings.outputDirectory = url
        }
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: settings.backgroundColor) },
            set: { settings.backgroundColor = $0.hexString() }
        )
    }
}
