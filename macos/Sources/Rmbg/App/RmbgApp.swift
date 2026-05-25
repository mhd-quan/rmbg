import SwiftUI

@main
struct RmbgApp: App {
    @State private var settings: SettingsStore
    @State private var recents: RecentsStore
    @State private var health: BackendHealthStore
    @State private var selection: SelectionStore
    @State private var banners: BannerCenter
    @State private var jobStore: JobStore

    // Locator + bridge held separately because they're consumed both as the
    // JobRunner inside JobStore and directly by the bootstrap task.
    @State private var locator: BackendLocator
    @State private var bridge: BackendBridge

    init() {
        let settings = SettingsStore()
        let recents = RecentsStore()
        let health = BackendHealthStore()
        let selection = SelectionStore()
        let banners = BannerCenter()
        let locator = BackendLocator(settings: settings)
        let bridge = BackendBridge(locator: locator, settings: settings)
        let jobs = JobStore(runner: bridge,
                            recents: recents,
                            settings: settings,
                            banners: banners)
        _settings = State(initialValue: settings)
        _recents = State(initialValue: recents)
        _health = State(initialValue: health)
        _selection = State(initialValue: selection)
        _banners = State(initialValue: banners)
        _locator = State(initialValue: locator)
        _bridge = State(initialValue: bridge)
        _jobStore = State(initialValue: jobs)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 900, minHeight: 600)
                .environment(settings)
                .environment(recents)
                .environment(health)
                .environment(selection)
                .environment(banners)
                .environment(jobStore)
                .task { await bootstrap() }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            AppCommands(
                jobStore: jobStore,
                selection: selection,
                settings: settings,
                banners: banners,
                recents: recents
            )
        }

        Settings {
            SettingsView()
                .environment(settings)
                .environment(health)
                .environment(banners)
        }
    }

    /// Runs once at app launch. Locates the backend, refreshes
    /// authentication and device info, and kicks off a background warmup.
    /// Failures surface through the banner center; the app remains usable so
    /// the user can correct settings.
    @MainActor
    private func bootstrap() async {
        AppLog.bootstrap.info("Starting bootstrap")

        // Cheap probe first — gives the sidebar footer something to show
        // without paying for `which`.
        health.backendExecutable = locator.probeWithoutWhich()
        if health.backendExecutable == nil {
            health.locatorError = "rmbg-backend not found."
            banners.post(.warning,
                         "Backend not found",
                         "Open Settings → Backend to choose the rmbg-backend executable.")
            return
        }

        // Auth status — show banner if not authenticated, but don't bail out
        // so the user can still inspect Recents.
        do {
            let auth = try await bridge.authStatus()
            health.auth = auth
            if !auth.authenticated {
                banners.post(.warning,
                             "Not signed in to Hugging Face",
                             auth.message)
            }
        } catch {
            AppLog.bootstrap.error("auth check failed: \(error.localizedDescription)")
            health.auth = AuthState(authenticated: false,
                                    username: nil,
                                    message: error.localizedDescription)
        }

        // Device detection.
        do {
            health.device = try await bridge.devices()
        } catch {
            AppLog.bootstrap.error("device probe failed: \(error.localizedDescription)")
        }

        // Warmup in the background — does not block the bootstrap.
        health.warmup = .warming
        Task.detached(priority: .utility) { @MainActor in
            do {
                let payload = try await bridge.warmup()
                health.warmup = .warmed
                health.device = DeviceState(auto: payload.device)
                AppLog.bootstrap.info("Warmup complete (\(payload.device))")
            } catch {
                health.warmup = .failed(message: error.localizedDescription)
                AppLog.bootstrap.error("warmup failed: \(error.localizedDescription)")
            }
        }
    }
}
