import Foundation
import Observation

/// Lifecycle of the backend model warmup. Sidebar footer mirrors this state.
enum WarmupState: Equatable, Hashable {
    case idle
    case warming
    case warmed
    case failed(message: String)

    var label: String {
        switch self {
        case .idle: return "Idle"
        case .warming: return "Warming model"
        case .warmed: return "Ready"
        case .failed(let msg): return "Error: \(msg)"
        }
    }
}

/// Live picture of backend reachability and authentication. Populated by
/// `RmbgApp` during launch and refreshed when the user re-checks from
/// Settings → Backend.
@MainActor
@Observable
final class BackendHealthStore {
    var auth: AuthState = .unknown
    var device: DeviceState = .unknown
    var warmup: WarmupState = .idle
    var backendExecutable: URL?
    var locatorError: String?

    var isReachable: Bool { backendExecutable != nil && locatorError == nil }
    var isReadyForWork: Bool { isReachable && auth.authenticated }
}

extension BackendHealthStore {
    static func preview(state: WarmupState = .warmed) -> BackendHealthStore {
        let store = BackendHealthStore()
        store.auth = AuthState(authenticated: true,
                               username: "preview-user",
                               message: "Authenticated")
        store.device = DeviceState(auto: "mps")
        store.warmup = state
        store.backendExecutable = URL(fileURLWithPath: "/Users/preview/.venv/bin/rmbg-backend")
        return store
    }
}
