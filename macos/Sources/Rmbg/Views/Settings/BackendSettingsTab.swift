import AppKit
import SwiftUI

/// Backend tab. Lets the user pick the `rmbg-backend` executable, choose
/// the inference device, override `HF_HOME`, and run a connectivity check.
struct BackendSettingsTab: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(BackendHealthStore.self) private var health
    @Environment(BannerCenter.self) private var banners

    @State private var testing: Bool = false
    @State private var testReport: TestReport?

    struct TestReport: Identifiable {
        let id = UUID()
        let auth: AuthState?
        let device: DeviceState?
        let error: String?
    }

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Executable") {
                LabeledContent("Backend path") {
                    HStack(spacing: Spacing.s) {
                        Text(settings.backendExecutableURL?.path ?? "Auto-detect")
                            .appFont(.body)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                        Button("Choose…") { pickExecutable() }
                            .controlSize(.small)
                        if settings.backendExecutableURL != nil {
                            Button("Reset") { settings.backendExecutableURL = nil }
                                .controlSize(.small)
                        }
                    }
                }
            }

            Section("Device") {
                Picker("Preferred device", selection: $settings.device) {
                    ForEach(DevicePreference.allCases) { device in
                        Text(device.displayName).tag(device)
                    }
                }
                LabeledContent("Detected") {
                    Text(health.device.auto)
                        .appFont(.monoSmall)
                        .foregroundStyle(Palette.textSecondary)
                }
            }

            Section("Hugging Face") {
                LabeledContent("Status") {
                    HStack(spacing: Spacing.s) {
                        Circle()
                            .fill(health.auth.authenticated ? Palette.Status.success : Palette.Status.failure)
                            .frame(width: 8, height: 8)
                        Text(health.auth.authenticated
                             ? "Authenticated as \(health.auth.username ?? "—")"
                             : health.auth.message)
                            .appFont(.body)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                LabeledContent("HF_HOME override") {
                    HStack(spacing: Spacing.s) {
                        Text(settings.hfHomeOverride?.path ?? "Auto")
                            .appFont(.body)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                        Button("Choose…") { pickHFHome() }
                            .controlSize(.small)
                        if settings.hfHomeOverride != nil {
                            Button("Reset") { settings.hfHomeOverride = nil }
                                .controlSize(.small)
                        }
                    }
                }
            }

            Section("Diagnostics") {
                HStack {
                    Button(testing ? "Testing…" : "Test backend") { Task { await runTest() } }
                        .disabled(testing)
                    if let report = testReport {
                        if let error = report.error {
                            HStack(spacing: Spacing.s) {
                                Circle().fill(Palette.Status.failure).frame(width: 8, height: 8)
                                Text(error).appFont(.body).foregroundStyle(Palette.Status.failure)
                            }
                        } else {
                            HStack(spacing: Spacing.s) {
                                Circle().fill(Palette.Status.success).frame(width: 8, height: 8)
                                Text("Device: \(report.device?.auto ?? "—") · \(report.auth?.username ?? "no user")")
                                    .appFont(.body)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(Spacing.l)
    }

    private func pickExecutable() {
        let panel = NSOpenPanel()
        panel.title = "Choose rmbg-backend"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.treatsFilePackagesAsDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            settings.backendExecutableURL = url
        }
    }

    private func pickHFHome() {
        let panel = NSOpenPanel()
        panel.title = "Choose HF_HOME directory"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            settings.hfHomeOverride = url
        }
    }

    private func runTest() async {
        testing = true
        defer { testing = false }
        let locator = BackendLocator(settings: settings)
        let bridge = BackendBridge(locator: locator, settings: settings)
        do {
            let auth = try await bridge.authStatus()
            let device = try await bridge.devices()
            testReport = TestReport(auth: auth, device: device, error: nil)
        } catch {
            testReport = TestReport(auth: nil, device: nil, error: error.localizedDescription)
        }
    }
}
