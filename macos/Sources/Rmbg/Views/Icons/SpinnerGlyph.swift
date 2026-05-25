import SwiftUI

/// Rotating 3/4 arc used to indicate in-flight work. Uses a `TimelineView`
/// scheduler so it animates without claiming `@State` from the host view.
struct SpinnerGlyph: View {
    var size: CGFloat = 16
    var lineWidth: CGFloat = 1.4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let revolution = seconds.truncatingRemainder(dividingBy: 1.2) / 1.2
            SpinnerArc()
                .stroke(style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(revolution * 360))
                .frame(width: size, height: size)
        }
    }
}

private struct SpinnerArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let radius = min(rect.width, rect.height) / 2 * 0.72
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(200),
                 clockwise: false)
        return p
    }
}

#Preview {
    SpinnerGlyph(size: 32, lineWidth: 1.6)
        .foregroundStyle(.tint)
        .padding(40)
}
