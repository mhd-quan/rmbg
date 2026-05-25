import SwiftUI

/// Software-drawn checkerboard background used behind RGBA cutouts so the
/// alpha channel is visually obvious. Adapts to the current color scheme
/// via `Palette.Checker`.
struct CheckerboardBackground: View {
    var squareSize: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let light = Palette.Checker.light
            let dark = Palette.Checker.dark

            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(light))

            let cols = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))
            var path = Path()
            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 1 {
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    path.addRect(rect)
                }
            }
            context.fill(path, with: .color(dark.opacity(0.5)))
        }
    }
}

#Preview {
    CheckerboardBackground()
        .frame(width: 320, height: 200)
}
