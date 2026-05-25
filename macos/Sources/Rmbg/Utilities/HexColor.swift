import SwiftUI

extension Color {
    /// Initialize a Color from a `#rrggbb` or `#rrggbbaa` hex string. Returns
    /// `Color.clear` for unparseable input rather than crashing.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&value),
              trimmed.count == 6 || trimmed.count == 8
        else {
            self = .clear
            return
        }

        let hasAlpha = trimmed.count == 8
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        if hasAlpha {
            r = Double((value >> 24) & 0xff) / 255.0
            g = Double((value >> 16) & 0xff) / 255.0
            b = Double((value >> 8) & 0xff) / 255.0
            a = Double(value & 0xff) / 255.0
        } else {
            r = Double((value >> 16) & 0xff) / 255.0
            g = Double((value >> 8) & 0xff) / 255.0
            b = Double(value & 0xff) / 255.0
            a = 1.0
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Convert the color to a `#rrggbb` (or `#rrggbbaa` if alpha < 1) string.
    /// Used when emitting export options to the backend.
    func hexString(includeAlpha: Bool = false) -> String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        if includeAlpha {
            let a = Int((ns.alphaComponent * 255).rounded())
            return String(format: "#%02x%02x%02x%02x", r, g, b, a)
        }
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
