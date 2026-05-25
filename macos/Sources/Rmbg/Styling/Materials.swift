import SwiftUI
import AppKit

/// Vibrant translucent backdrops via `NSVisualEffectView`. SwiftUI's
/// built-in `Material` doesn't give us all of NSVisualEffectView's materials
/// (most importantly `.sidebar` with proper sidebar tinting), so we bridge.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var emphasized: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = emphasized
        view.state = .followsWindowActiveState
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = emphasized
    }
}

extension View {
    /// Sidebar material — slightly more vibrant; tints with the accent color
    /// when the sidebar contains the selection.
    func sidebarMaterial() -> some View {
        background(VisualEffectBackground(material: .sidebar))
    }

    /// Default content backdrop used for the library, batch queue, detail.
    func contentMaterial() -> some View {
        background(VisualEffectBackground(material: .contentBackground))
    }

    /// HUD-style material used for floating action menus and toasts.
    func hudMaterial() -> some View {
        background(VisualEffectBackground(material: .hudWindow,
                                          blendingMode: .withinWindow))
    }

    /// Window backdrop — the absolute base layer.
    func windowMaterial() -> some View {
        background(VisualEffectBackground(material: .windowBackground))
    }
}
