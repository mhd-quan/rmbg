import AppKit
import SwiftUI

/// Rich failure surface for a single-image job. Shows the original image as
/// a muted backdrop, a card with the human-readable error, a scrollable
/// stderr/log preview, and clear actions (Retry, Open Original, Remove).
struct DetailFailureView: View {
    @Bindable var job: ImageJob
    @Environment(JobStore.self) private var jobs
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openSettings) private var openSettings

    @State private var beforeImage: NSImage?

    private var errorMessage: String { job.error ?? "Background removal failed." }

    var body: some View {
        ZStack {
            // Subtle backdrop of the original so the failure has visual
            // context — the user remembers which image they tried.
            backdrop

            VStack(alignment: .leading, spacing: Spacing.l) {
                heading
                logBox
                actionRow
                Spacer(minLength: 0)
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 640, alignment: .leading)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: Spacing.Radius.l,
                                             style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous)
                    .stroke(Palette.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
            .padding(Spacing.xxl)
        }
        .task(id: job.id) { await loadBefore() }
    }

    // MARK: - Sections

    private var heading: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(Palette.Status.failure.opacity(0.15))
                    .frame(width: 36, height: 36)
                GlyphView<WarningGlyph>(size: 18, lineWidth: 1.3)
                    .foregroundStyle(Palette.Status.failure)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Background removal failed")
                    .appFont(.titleM)
                    .foregroundStyle(Palette.textPrimary)
                Text(filenameText)
                    .appFont(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
    }

    private var logBox: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Error")
                    .appFont(.caption)
                    .foregroundStyle(Palette.textTertiary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(errorMessage, forType: .string)
                } label: {
                    HStack(spacing: 4) {
                        GlyphView<ExportGlyph>(size: 12, lineWidth: 1)
                            .rotationEffect(.degrees(180))
                        Text("Copy")
                            .appFont(.callout)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.textSecondary)
                .help("Copy error message to clipboard")
            }

            ScrollView {
                Text(errorMessage)
                    .appFont(.monoSmall)
                    .foregroundStyle(Palette.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.m)
            }
            .frame(maxHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: Spacing.Radius.s, style: .continuous)
                    .fill(Palette.surface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.Radius.s, style: .continuous)
                    .stroke(Palette.border, lineWidth: 1)
            )

            if isLikelyMPSOOM {
                hint(
                    "Looks like an MPS out-of-memory error. Open Settings → Backend and switch the device to CPU, then retry."
                )
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: Spacing.s) {
            Button {
                jobs.retry(job)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .appFont(.callout)
                    .padding(.horizontal, Spacing.s)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button {
                if case .single(let url) = job.kind {
                    FileManager.reveal(url)
                }
            } label: {
                HStack(spacing: 4) {
                    GlyphView<RevealGlyph>(size: 12, lineWidth: 1)
                    Text("Show original")
                        .appFont(.callout)
                }
                .padding(.horizontal, Spacing.s)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button { openSettings() } label: {
                HStack(spacing: 4) {
                    GlyphView<SettingsGlyph>(size: 12, lineWidth: 1)
                    Text("Settings")
                        .appFont(.callout)
                }
                .padding(.horizontal, Spacing.s)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            Button(role: .destructive) {
                jobs.remove(job)
            } label: {
                Text("Discard")
                    .appFont(.callout)
                    .padding(.horizontal, Spacing.s)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private func hint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            GlyphView<WarningGlyph>(size: 12, lineWidth: 1)
                .foregroundStyle(.orange)
            Text(text)
                .appFont(.callout)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Spacing.Radius.s, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Backdrop

    @ViewBuilder
    private var backdrop: some View {
        ZStack {
            CheckerboardBackground().opacity(0.35)
            if let beforeImage {
                Image(nsImage: beforeImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .padding(Spacing.xxxl)
                    .opacity(0.18)
                    .blur(radius: 6)
            }
        }
    }

    private var filenameText: String {
        if case .single(let url) = job.kind { return url.lastPathComponent }
        return job.kind.displayTitle
    }

    private var isLikelyMPSOOM: Bool {
        let lower = errorMessage.lowercased()
        return lower.contains("mps") && (lower.contains("out of memory")
                                         || lower.contains("oom"))
    }

    @MainActor
    private func loadBefore() async {
        guard case .single(let url) = job.kind else { return }
        beforeImage = await ThumbnailCache.shared.thumbnail(for: url, maxPixelSize: 1024)
    }
}

#Preview {
    DetailFailureView(
        job: {
            let j = ImageJob.previewSingle(named: "ChatGPT Image May 24, 2026, 01_51_29 AM.png")
            j.status = .failed(message: """
RuntimeError: MPS backend out of memory (MPS allocated: 1.92 GB, other allocations: \
4.83 GB, max allowed: 6.77 GB). Tried to allocate 48.00 MB on private pool.
""")
            j.error = """
RuntimeError: MPS backend out of memory (MPS allocated: 1.92 GB, other allocations: \
4.83 GB, max allowed: 6.77 GB). Tried to allocate 48.00 MB on private pool.
"""
            return j
        }()
    )
    .environment(JobStore.preview())
    .environment(SettingsStore.preview())
    .frame(width: 900, height: 600)
}
