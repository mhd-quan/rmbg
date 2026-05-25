import SwiftUI

/// Rounded pill displaying a small count, e.g. number of active items in a
/// sidebar section. Hidden automatically when `count` is 0.
struct CountBadge: View {
    let count: Int
    var tint: Color = Palette.textSecondary

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .appFont(.monoSmall)
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .foregroundStyle(tint)
                .background(
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.12))
                )
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        CountBadge(count: 0)
        CountBadge(count: 3)
        CountBadge(count: 12)
        CountBadge(count: 128, tint: .red)
    }
    .padding(24)
}
