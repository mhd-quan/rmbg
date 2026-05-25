import SwiftUI

/// Discrete haptic events the app fires. The enum exists so all triggers
/// are auditable in one place. Apply via `.appHaptic(.sliderSnap, trigger: x)`
/// — the modifier honors `SettingsStore.hapticsEnabled`.
enum HapticTrigger: Hashable {
    case sliderSnap
    case dragEnter
    case dropAccept
    case batchItemComplete
    case exportComplete
    case selectionChange

    var feedback: SensoryFeedback {
        switch self {
        case .sliderSnap: return .alignment
        case .dragEnter: return .selection
        case .dropAccept: return .impact(weight: .medium)
        case .batchItemComplete: return .success
        case .exportComplete: return .success
        case .selectionChange: return .selection
        }
    }
}

extension View {
    /// Fire a haptic feedback event whenever `trigger` changes. The modifier
    /// reads the global `SettingsStore.hapticsEnabled` flag from the
    /// environment; when disabled the feedback is suppressed.
    func appHaptic<T: Equatable>(_ event: HapticTrigger, trigger: T) -> some View {
        modifier(AppHapticModifier(event: event, trigger: AnyEquatableBox(trigger)))
    }
}

private struct AppHapticModifier: ViewModifier {
    @Environment(SettingsStore.self) private var settings
    let event: HapticTrigger
    let trigger: AnyEquatableBox

    func body(content: Content) -> some View {
        content.sensoryFeedback(event.feedback, trigger: trigger) { _, _ in
            settings.hapticsEnabled
        }
    }
}

/// Type-erased equatable box so the modifier can accept any value.
private struct AnyEquatableBox: Equatable {
    private let value: Any
    private let isEqual: (Any) -> Bool

    init<T: Equatable>(_ value: T) {
        self.value = value
        self.isEqual = { other in (other as? T) == value }
    }

    static func == (lhs: AnyEquatableBox, rhs: AnyEquatableBox) -> Bool {
        lhs.isEqual(rhs.value)
    }
}
