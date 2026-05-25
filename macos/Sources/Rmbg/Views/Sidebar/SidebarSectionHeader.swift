import SwiftUI

/// Small uppercased header used to label sidebar groups. Lifts from Things 3
/// and ChatGPT: thin tracked caps in a muted color.
struct SidebarSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .appFont(.caption)
            .foregroundStyle(Palette.textTertiary)
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 0) {
        SidebarSectionHeader(title: "Work")
        SidebarSectionHeader(title: "History")
    }
    .frame(width: 240)
}
