import SwiftUI

/// Thin hairline progress bar used in batch rows and aggregate headers.
struct ProgressBarHairline: View {
    var progress: Double
    var height: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Palette.border)
                Capsule(style: .continuous)
                    .fill(Palette.accent)
                    .frame(width: max(2, proxy.size.width * clamped))
                    .animation(AppAnimation.smooth, value: progress)
            }
        }
        .frame(height: height)
    }

    private var clamped: Double { min(1.0, max(0.0, progress)) }
}

#Preview {
    VStack(spacing: 12) {
        ProgressBarHairline(progress: 0)
        ProgressBarHairline(progress: 0.4)
        ProgressBarHairline(progress: 1)
    }
    .padding(24)
    .frame(width: 320)
}
