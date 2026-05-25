import AppKit
import SwiftUI

/// Before/after slider inspired by Gigapixel AI: a vertical divider that
/// reveals the cutout on the right and the original image on the left.
/// Dragging the handle (or anywhere on the canvas) repositions the divider;
/// it soft-snaps to 0%, 50%, and 100% and fires a haptic each time the
/// divider crosses into a snap zone. Hold ⎵ Space to peek the full cutout.
struct BeforeAfterSlider: View {
    let beforeImage: NSImage
    let afterImage: NSImage
    var paddingInset: CGFloat = Spacing.xxxl

    @State private var dividerFraction: Double = 0.5
    @State private var lastSnapZone: Int = 1
    @State private var spaceHeld: Bool = false

    /// Effective fraction used to draw. When ⎵ is held we ignore the user's
    /// fraction and show the cutout in full.
    private var visibleFraction: Double { spaceHeld ? 0.0 : dividerFraction }

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = proxy.size
            let width = canvasSize.width
            let dividerX = max(0, min(width, width * visibleFraction))

            ZStack(alignment: .topLeading) {
                CheckerboardBackground()
                    .opacity(0.45)

                Image(nsImage: beforeImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: canvasSize.height)

                Image(nsImage: afterImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: canvasSize.height)
                    .mask(alignment: .leading) {
                        HStack(spacing: 0) {
                            Color.clear.frame(width: dividerX)
                            Rectangle()
                        }
                    }

                // Divider line + handle, suppressed while space-peeking.
                if !spaceHeld {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1.5)
                        .offset(x: dividerX - 0.75)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 0)

                    handle
                        .offset(x: dividerX - 22, y: canvasSize.height / 2 - 22)
                }

                if spaceHeld { spaceHint }
            }
            .padding(paddingInset)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: max(1, width)))
            .focusable()
            .onKeyPress(keys: [.space], phases: [.down, .up]) { press in
                spaceHeld = press.phase == .down
                return .handled
            }
        }
        .appHaptic(.sliderSnap, trigger: lastSnapZone)
        .animation(AppAnimation.snappy, value: spaceHeld)
    }

    // MARK: - Handle

    private var handle: some View {
        Circle()
            .fill(.regularMaterial)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(Palette.border, lineWidth: 1)
            )
            .overlay(
                GlyphView<ChevronLeftRightGlyph>(size: 18, lineWidth: 1.3)
                    .foregroundStyle(Palette.textPrimary)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 2)
    }

    private var spaceHint: some View {
        VStack {
            HStack {
                Spacer()
                Text("CUTOUT")
                    .appFont(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 3)
                    .background(Palette.accent.opacity(0.85), in: Capsule(style: .continuous))
                    .padding(Spacing.l)
            }
            Spacer()
        }
    }

    // MARK: - Drag

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !spaceHeld else { return }
                let raw = (value.location.x - paddingInset) / max(1, width - paddingInset * 2)
                let clamped = min(1, max(0, raw))
                let snapped = applySoftSnap(clamped)
                dividerFraction = snapped
                updateSnapZone(for: snapped)
            }
            .onEnded { _ in
                guard !spaceHeld else { return }
                let snapped = applySoftSnap(dividerFraction)
                withAnimation(AppAnimation.spring) {
                    dividerFraction = snapped
                }
            }
    }

    /// Soft snap — values within ±2% of 0/50/100% pin to the exact value.
    private func applySoftSnap(_ value: Double) -> Double {
        for anchor in [0.0, 0.5, 1.0] where abs(value - anchor) < 0.02 {
            return anchor
        }
        return value
    }

    /// Update the last-reached snap zone so the haptic modifier sees a
    /// changed value when the user crosses INTO a snap point. Leaving a zone
    /// does not trigger haptic.
    private func updateSnapZone(for value: Double) {
        let zone: Int
        if value <= 0.001 { zone = 0 }
        else if value >= 0.999 { zone = 2 }
        else if abs(value - 0.5) < 0.005 { zone = 1 }
        else { zone = -1 }
        if zone != -1 && zone != lastSnapZone { lastSnapZone = zone }
    }
}

#Preview("Slider (placeholder)") {
    // The preview can't load real images from disk, so this just confirms
    // layout — drag the canvas to move the divider on a checkerboard.
    GeometryReader { _ in
        BeforeAfterSlider(
            beforeImage: NSImage(systemSymbolName: "photo", accessibilityDescription: nil) ?? NSImage(),
            afterImage: NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) ?? NSImage()
        )
    }
    .environment(SettingsStore.preview())
    .frame(width: 720, height: 480)
}
