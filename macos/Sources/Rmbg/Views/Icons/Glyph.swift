import SwiftUI

/// Marker protocol that every monolinear glyph in the app conforms to. All
/// glyphs design against a 24×24 viewbox; `unitTransform(in:)` scales that
/// design into the target rect while preserving aspect.
protocol Glyph: Shape {
    init()
}

extension Glyph {
    /// Linear transform that maps the 24-unit design space to `rect`.
    func unitTransform(in rect: CGRect) -> CGAffineTransform {
        let scale = min(rect.width, rect.height) / 24.0
        let dx = rect.minX + (rect.width - 24 * scale) / 2.0
        let dy = rect.minY + (rect.height - 24 * scale) / 2.0
        return CGAffineTransform(translationX: dx, y: dy)
            .scaledBy(x: scale, y: scale)
    }
}

/// Renders any `Glyph` with the canonical 1pt monolinear stroke. The visual
/// weight is intentionally lighter than SF Symbols — closer to Nucleo Micro
/// Bold, which favors hairlines and round caps over filled blocks.
struct GlyphView<G: Glyph>: View {
    var size: CGFloat = 16
    var lineWidth: CGFloat = 1.0
    var dashed: Bool = false

    var body: some View {
        G()
            .stroke(style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: dashed ? [3, 3] : []
            ))
            .frame(width: size, height: size)
    }
}

// MARK: - Unit-space helpers

/// Add a "dot" to a path by drawing a tiny segment that, when stroked with
/// `lineCap: .round`, renders as a 1pt filled circle. This lets a single
/// stroke pass paint both lines and dots without needing a separate fill.
func unitDot(in path: inout Path, at point: CGPoint) {
    path.move(to: CGPoint(x: point.x - 0.001, y: point.y))
    path.addLine(to: CGPoint(x: point.x + 0.001, y: point.y))
}

/// Add a rounded rectangle in unit space.
func unitRoundedRect(
    in path: inout Path,
    x: CGFloat, y: CGFloat,
    width: CGFloat, height: CGFloat,
    radius: CGFloat
) {
    let rect = CGRect(x: x, y: y, width: width, height: height)
    path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
}

#Preview("Glyph viewbox") {
    HStack(spacing: 16) {
        GlyphView<LibraryGlyph>(size: 24)
        GlyphView<BatchGlyph>(size: 24)
        GlyphView<RecentGlyph>(size: 24)
        GlyphView<SettingsGlyph>(size: 24)
    }
    .padding(24)
    .foregroundStyle(.primary)
}
