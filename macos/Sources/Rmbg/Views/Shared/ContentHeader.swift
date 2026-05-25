import SwiftUI

/// Prominent section header rendered at the top of each content column.
/// Replaces `.navigationTitle` + `.navigationSubtitle` for a richer
/// typography hierarchy and consistent placement across all sections.
struct ContentHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .appFont(.titleL)
                        .foregroundStyle(Palette.textPrimary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .appFont(.body)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                trailing()
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.m)

            Rectangle()
                .fill(Palette.border)
                .frame(height: 0.5)
        }
    }
}

extension ContentHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}

#Preview {
    VStack(spacing: 0) {
        ContentHeader(title: "Library", subtitle: "3 images")
        ContentHeader(title: "Batch Queue", subtitle: "1 running") {
            Button("Clear all") {}.controlSize(.small)
        }
        ContentHeader(title: "Recents")
        Spacer()
    }
    .frame(width: 700, height: 400)
}
