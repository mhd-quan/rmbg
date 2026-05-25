import SwiftUI

/// Settings scene root. Renders as a tabbed sheet that the system opens for
/// ⌘, via the `Settings { ... }` scene in `RmbgApp`.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            OutputSettingsTab()
                .tabItem {
                    Label("Output", systemImage: "square.and.arrow.up")
                }
            BackendSettingsTab()
                .tabItem {
                    Label("Backend", systemImage: "cpu")
                }
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 420)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsStore.preview())
        .environment(BackendHealthStore.preview())
        .environment(BannerCenter.preview())
}
