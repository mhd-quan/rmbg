import SwiftUI

/// The window's root SwiftUI surface. A three-pane `NavigationSplitView`
/// with a Things 3-style sidebar, a content column that switches based on
/// the selected section, and a detail column that renders the selected job.
/// Banners overlay the entire window at the top.
struct RootView: View {
    @Environment(SelectionStore.self) private var selection
    @Environment(JobStore.self) private var jobs
    @Environment(BannerCenter.self) private var banners

    var body: some View {
        @Bindable var selection = selection
        NavigationSplitView(columnVisibility: visibility(selection: selection)) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        } content: {
            content
                .navigationSplitViewColumnWidth(min: 360, ideal: 520)
        } detail: {
            DetailView()
                .navigationSplitViewColumnWidth(min: 360, ideal: 600)
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            BannerStack()
                .padding(.top, Spacing.s)
                .padding(.horizontal, Spacing.l)
        }
        .dropTargetForImages()
    }

    private func visibility(selection: SelectionStore) -> Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { selection.sidebarVisible ? .all : .detailOnly },
            set: { newValue in
                selection.sidebarVisible = (newValue != .detailOnly)
            }
        )
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch selection.section {
            case .library: LibraryView()
            case .batch: BatchQueueView()
            case .recents: RecentsView()
            }
        }
        .id(selection.section)
        .transition(.opacity)
        .animation(AppAnimation.smooth, value: selection.section)
    }
}

/// Stack of transient banners. Auto-dismissed by `BannerCenter`. Animated
/// inserts/removes use the project's `snappy` token.
private struct BannerStack: View {
    @Environment(BannerCenter.self) private var banners

    var body: some View {
        VStack(spacing: Spacing.s) {
            ForEach(banners.banners) { banner in
                BannerRow(banner: banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.snappy, value: banners.banners.map(\.id))
        .frame(maxWidth: 520)
    }
}

private struct BannerRow: View {
    let banner: BannerCenter.Banner
    @Environment(BannerCenter.self) private var center

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            glyph
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).appFont(.bodyEmphasized)
                if let message = banner.message {
                    Text(message)
                        .appFont(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: Spacing.s)
            Button {
                center.dismiss(id: banner.id)
            } label: {
                GlyphView<MoreGlyph>(size: 14, lineWidth: 1)
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(Palette.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var glyph: some View {
        switch banner.kind {
        case .info, .success: GlyphView<CheckmarkGlyph>(size: 14, lineWidth: 1.2)
        case .warning, .error: GlyphView<WarningGlyph>(size: 14, lineWidth: 1.2)
        }
    }

    private var tint: Color {
        switch banner.kind {
        case .info: return Palette.accent
        case .success: return Palette.Status.success
        case .warning: return .orange
        case .error: return Palette.Status.failure
        }
    }
}

#Preview {
    RootView()
        .environment(JobStore.preview())
        .environment(RecentsStore.preview())
        .environment(SettingsStore.preview())
        .environment(BackendHealthStore.preview())
        .environment(SelectionStore.preview())
        .environment(BannerCenter.preview())
        .frame(width: 1100, height: 700)
}
