import Foundation
import Observation

/// Top-level transient banner messages — used for backend errors that the
/// user must see but that don't belong inside a specific job row.
@MainActor
@Observable
final class BannerCenter {
    private(set) var banners: [Banner] = []
    @ObservationIgnored private var nextID: UInt = 0

    struct Banner: Identifiable, Equatable {
        let id: UInt
        let kind: Kind
        let title: String
        let message: String?

        enum Kind: Equatable {
            case info, warning, error, success
        }
    }

    func post(_ kind: Banner.Kind, _ title: String, _ message: String? = nil,
              autoDismiss: TimeInterval? = 6.0) {
        nextID += 1
        let banner = Banner(id: nextID, kind: kind, title: title, message: message)
        banners.append(banner)
        if let autoDismiss {
            let id = banner.id
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(autoDismiss * 1_000_000_000))
                self?.dismiss(id: id)
            }
        }
    }

    func dismiss(id: UInt) {
        banners.removeAll { $0.id == id }
    }

    func dismissAll() {
        banners.removeAll()
    }
}

extension BannerCenter {
    static func preview() -> BannerCenter { BannerCenter() }
}
