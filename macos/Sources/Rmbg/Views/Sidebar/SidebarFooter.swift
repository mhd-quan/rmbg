import SwiftUI

/// Footer pinned to the bottom of the sidebar. Surfaces backend health
/// (device + warmup state). Tapping the pill jumps to Settings → Backend.
struct SidebarFooter: View {
    @Environment(BackendHealthStore.self) private var health
    @Environment(\.openSettings) private var openSettings
    @State private var isHovered = false

    var body: some View {
        Button {
            openSettings()
        } label: {
            HStack(spacing: Spacing.s) {
                indicator
                VStack(alignment: .leading, spacing: 1) {
                    Text(deviceLabel)
                        .appFont(.callout)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Text(stateLabel)
                        .appFont(.caption)
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                GlyphView<ChevronLeftRightGlyph>(size: 10, lineWidth: 1)
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(Palette.textTertiary.opacity(isHovered ? 1 : 0))
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.Radius.m, style: .continuous)
                    .stroke(Palette.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Backend status. Click to open Settings.")
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering }
        }
    }

    @ViewBuilder
    private var indicator: some View {
        ZStack {
            Circle()
                .fill(indicatorColor.opacity(0.18))
                .frame(width: 22, height: 22)
            indicatorGlyph
        }
    }

    @ViewBuilder
    private var indicatorGlyph: some View {
        switch health.warmup {
        case .warming:
            SpinnerGlyph(size: 11, lineWidth: 1.2)
                .foregroundStyle(Palette.accent)
        case .warmed:
            Circle()
                .fill(Palette.Status.success)
                .frame(width: 7, height: 7)
        case .failed:
            GlyphView<WarningGlyph>(size: 11, lineWidth: 1.2)
                .foregroundStyle(Palette.Status.failure)
        case .idle:
            Circle()
                .fill(Palette.textTertiary)
                .frame(width: 7, height: 7)
        }
    }

    private var indicatorColor: Color {
        switch health.warmup {
        case .warming: return Palette.accent
        case .warmed: return Palette.Status.success
        case .failed: return Palette.Status.failure
        case .idle: return Palette.textTertiary
        }
    }

    private var deviceLabel: String {
        if health.backendExecutable == nil { return "Backend not found" }
        return "Device · \(health.device.auto)"
    }

    private var stateLabel: String {
        switch health.warmup {
        case .idle: return health.auth.authenticated ? "Idle" : health.auth.message
        case .warming: return "Loading model…"
        case .warmed: return "Ready"
        case .failed(let msg): return msg
        }
    }
}

#Preview("Warmed") {
    SidebarFooter()
        .environment(BackendHealthStore.preview(state: .warmed))
        .padding(12)
        .frame(width: 260)
}

#Preview("Warming") {
    SidebarFooter()
        .environment(BackendHealthStore.preview(state: .warming))
        .padding(12)
        .frame(width: 260)
}

#Preview("Failed") {
    SidebarFooter()
        .environment(BackendHealthStore.preview(state: .failed(message: "MPS OOM")))
        .padding(12)
        .frame(width: 260)
}
