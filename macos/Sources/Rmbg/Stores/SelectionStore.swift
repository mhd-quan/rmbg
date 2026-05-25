import Foundation
import Observation

/// The currently selected section plus the focused job inside that section.
/// `showInspector` controls the trailing inspector that surfaces metadata.
@MainActor
@Observable
final class SelectionStore {
    var section: AppSection = .library
    var selectedJobID: UUID?
    var showInspector: Bool = false
    var sidebarVisible: Bool = true

    func select(section: AppSection) {
        self.section = section
        selectedJobID = nil
    }

    func select(jobID: UUID?) {
        selectedJobID = jobID
    }

    func toggleSidebar() {
        sidebarVisible.toggle()
    }
}

extension SelectionStore {
    static func preview(section: AppSection = .library) -> SelectionStore {
        let store = SelectionStore()
        store.section = section
        return store
    }
}
