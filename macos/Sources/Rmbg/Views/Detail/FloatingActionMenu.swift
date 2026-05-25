import AppKit
import SwiftUI

/// Floating action menu pinned to the bottom-trailing of the detail surface.
/// Avoids the top window toolbar entirely. Buttons are framed as a single
/// HUD-material capsule so they read as one cohesive control.
struct FloatingActionMenu: View {
    @Bindable var job: ImageJob
    @Environment(JobStore.self) private var jobs
    @Environment(SettingsStore.self) private var settings
    @Environment(BannerCenter.self) private var banners

    var body: some View {
        HStack(spacing: 0) {
            actionButton(glyph: ExportGlyph.self,
                         title: "Export…",
                         shortcut: KeyboardShortcut("s", modifiers: [.command, .shift])) {
                exportAs()
            }
            divider
            actionButton(glyph: RevealGlyph.self,
                         title: "Reveal",
                         shortcut: KeyboardShortcut("r", modifiers: [.command])) {
                reveal()
            }
            divider
            actionButton(glyph: MaximizeGlyph.self,
                         title: "Fullscreen",
                         shortcut: nil) {
                toggleFullScreen()
            }
            divider
            Menu {
                Button("Remove from library") { jobs.remove(job) }
                if case .failed = job.status {
                    Button("Retry") { jobs.retry(job) }
                }
            } label: {
                GlyphView<MoreGlyph>(size: 16, lineWidth: 1.1)
                    .padding(Spacing.s)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 36)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule(style: .continuous).stroke(Palette.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.border)
            .frame(width: 1, height: 22)
    }

    @ViewBuilder
    private func actionButton<G: Glyph>(
        glyph: G.Type,
        title: String,
        shortcut: KeyboardShortcut?,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            GlyphView<G>(size: 16, lineWidth: 1.1)
                .padding(Spacing.s)
        }
        .buttonStyle(.plain)
        .help(title)

        if let shortcut {
            button.keyboardShortcut(shortcut)
        } else {
            button
        }
    }

    // MARK: - Actions

    private func exportAs() {
        guard let result = job.singleResult else { return }
        let panel = NSSavePanel()
        panel.title = "Export cutout"
        panel.nameFieldStringValue = URL(fileURLWithPath: result.outputPath).lastPathComponent
        panel.allowedContentTypes = [.png, .jpeg, .webP, .tiff]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let destination = panel.url {
            do {
                try FileManager.default.copyItem(
                    at: URL(fileURLWithPath: result.outputPath),
                    to: destination
                )
                banners.post(.success, "Exported", destination.lastPathComponent)
                if settings.revealAfterExport {
                    FileManager.reveal(destination)
                }
            } catch {
                banners.post(.error, "Export failed", error.localizedDescription)
            }
        }
    }

    private func reveal() {
        guard let result = job.singleResult else { return }
        FileManager.reveal(URL(fileURLWithPath: result.outputPath))
    }

    private func toggleFullScreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }
}
