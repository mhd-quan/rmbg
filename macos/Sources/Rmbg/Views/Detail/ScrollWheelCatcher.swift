import AppKit
import SwiftUI

/// A small NSView that forwards trackpad scroll-wheel events as 2D deltas.
/// Used by `ZoomPanContainer` to pan the content with a two-finger trackpad
/// swipe — keeping pan off the `DragGesture` so the BeforeAfterSlider's
/// drag isn't intercepted.
struct ScrollWheelCatcher: NSViewRepresentable {
    var onScroll: (CGSize) -> Void

    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: WheelView, context: Context) {
        nsView.onScroll = onScroll
    }

    final class WheelView: NSView {
        var onScroll: ((CGSize) -> Void)?

        override var acceptsFirstResponder: Bool { false }

        override func scrollWheel(with event: NSEvent) {
            onScroll?(CGSize(width: event.scrollingDeltaX,
                             height: event.scrollingDeltaY))
        }
    }
}
