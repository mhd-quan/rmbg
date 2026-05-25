import SwiftUI

/// Named animation curves used across the app.
enum AppAnimation {
    /// Quick utility transitions: button presses, badge pulses, selection ticks.
    static let snappy = Animation.snappy(duration: 0.22)

    /// Smooth content swaps: section changes, inspector toggles, sidebar.
    static let smooth = Animation.smooth(duration: 0.35)

    /// Interactive spring for the before/after slider release.
    static let spring = Animation.interactiveSpring(response: 0.30,
                                                    dampingFraction: 0.85)

    /// Slow material crossfade — used for empty/non-empty transitions.
    static let slowFade = Animation.smooth(duration: 0.5)
}
