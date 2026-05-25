import AppKit
import SwiftUI

/// General tab. Surfaces broad UX preferences that don't fit elsewhere.
struct GeneralSettingsTab: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Interaction") {
                Toggle("Enable haptic feedback", isOn: $settings.hapticsEnabled)
                    .help("Tactile pulses for slider snaps, drag/drop, and batch completion. Requires a Force Touch trackpad.")
                Toggle("Reveal in Finder after export", isOn: $settings.revealAfterExport)
            }
        }
        .formStyle(.grouped)
        .padding(Spacing.l)
    }
}
