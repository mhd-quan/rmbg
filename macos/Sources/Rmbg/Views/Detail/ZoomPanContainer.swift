import AppKit
import SwiftUI

/// Wraps content with pinch-to-zoom (25–400%) and two-finger trackpad
/// panning. A double-click resets to 100% and centers the content. We
/// intentionally route panning through `ScrollWheelCatcher` rather than a
/// `DragGesture` so it doesn't collide with the BeforeAfterSlider's drag.
struct ZoomPanContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var snapZoom: Int = 1

    private let minScale: CGFloat = 0.25
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            content()
                .scaleEffect(scale, anchor: .center)
                .offset(offset)
                .background(
                    ScrollWheelCatcher { delta in
                        guard scale > 1.001 else { return }
                        offset.width += delta.width
                        offset.height += delta.height
                    }
                )
                .gesture(magnificationGesture)
                .onTapGesture(count: 2) { reset() }
        }
        .overlay(alignment: .topTrailing) { zoomChip }
        .clipped()
        .appHaptic(.sliderSnap, trigger: snapZoom)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let next = min(maxScale, max(minScale, lastScale * value))
                scale = next
                updateZoomSnap(for: next)
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    @ViewBuilder
    private var zoomChip: some View {
        if scale != 1.0 {
            Text(zoomText)
                .appFont(.monoSmall)
                .foregroundStyle(Palette.textSecondary)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: Capsule(style: .continuous))
                .overlay(Capsule(style: .continuous).stroke(Palette.border, lineWidth: 1))
                .padding(Spacing.l)
                .transition(.opacity)
        }
    }

    private var zoomText: String {
        String(format: "%.0f%%", scale * 100)
    }

    private func reset() {
        withAnimation(AppAnimation.spring) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
        }
        snapZoom = 1
    }

    /// Fire haptic when crossing common zoom milestones (50%, 100%, 200%).
    private func updateZoomSnap(for value: CGFloat) {
        let zone: Int
        switch value {
        case _ where abs(value - 0.5) < 0.02: zone = 0
        case _ where abs(value - 1.0) < 0.02: zone = 1
        case _ where abs(value - 2.0) < 0.04: zone = 2
        case _ where abs(value - 4.0) < 0.05: zone = 3
        default: zone = -1
        }
        if zone != -1 && zone != snapZoom { snapZoom = zone }
    }
}
