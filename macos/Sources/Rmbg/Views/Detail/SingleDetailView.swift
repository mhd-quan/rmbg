import AppKit
import SwiftUI

/// Detail surface for a single-image job. Shows a large canvas with the
/// processed cutout sitting on a checkerboard, a metadata strip below, and
/// a floating action menu in the trailing-bottom corner. The before/after
/// slider lives inside the canvas — added in Task #8.
struct SingleDetailView: View {
    @Bindable var job: ImageJob
    @State private var loader = DetailImageLoader()

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            DetailMetadataStrip(result: job.singleResult, job: job)
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionMenu(job: job)
                .padding(Spacing.xl)
                .opacity(job.singleResult == nil ? 0 : 1)
        }
        .task(id: job.id) { await loader.load(for: job) }
        .task(id: job.singleResult?.outputPath) { await loader.load(for: job) }
        .navigationTitle(job.kind.displayTitle)
        .navigationSubtitle(subtitle)
    }

    private var subtitle: String {
        switch job.status {
        case .pending: return "Waiting…"
        case .warming: return "Warming model"
        case .processing: return "Removing background"
        case .partial(let d, let t): return "\(d) of \(t)"
        case .succeeded:
            if let r = job.singleResult { return "\(r.width) × \(r.height)" }
            return ""
        case .failed: return job.error ?? "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    @ViewBuilder
    private var canvas: some View {
        ZStack {
            if case .failed = job.status {
                DetailFailureView(job: job)
                    .transition(.opacity)
            } else if let before = loader.beforeImage, let after = loader.afterImage {
                ZoomPanContainer {
                    BeforeAfterSlider(beforeImage: before, afterImage: after)
                }
                .transition(.opacity)
            } else if let before = loader.beforeImage, !job.status.isTerminal {
                ZStack {
                    CheckerboardBackground().opacity(0.6)
                    Image(nsImage: before)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .padding(Spacing.xxxl)
                        .opacity(0.35)
                    progressOverlay
                }
            } else if loader.isLoading {
                SpinnerGlyph(size: 28, lineWidth: 1.4)
                    .foregroundStyle(Palette.accent)
            } else {
                placeholderHint
            }
        }
        .animation(AppAnimation.smooth, value: loader.afterImage != nil)
        .animation(AppAnimation.smooth, value: job.status)
    }

    @ViewBuilder
    private var progressOverlay: some View {
        VStack(spacing: Spacing.s) {
            SpinnerGlyph(size: 24, lineWidth: 1.4)
                .foregroundStyle(Palette.accent)
            Text(job.status.isRunning ? "Removing background…" : "")
                .appFont(.bodyEmphasized)
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(Spacing.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Spacing.Radius.l, style: .continuous))
    }

    private var placeholderHint: some View {
        VStack(spacing: Spacing.s) {
            GlyphView<ImageGlyph>(size: 36, lineWidth: 1.2)
                .foregroundStyle(Palette.textTertiary)
            Text("No preview available")
                .appFont(.body)
                .foregroundStyle(Palette.textTertiary)
        }
    }
}

#Preview("Succeeded") {
    SingleDetailView(job: .previewSingle(named: "lighthouse.jpg"))
        .environment(JobStore.preview())
        .environment(SettingsStore.preview())
        .environment(BannerCenter.preview())
        .frame(width: 800, height: 600)
}

#Preview("Processing") {
    SingleDetailView(job: .previewSingle(named: "robot.png", status: .processing(progress: 0.4)))
        .environment(JobStore.preview())
        .environment(SettingsStore.preview())
        .environment(BannerCenter.preview())
        .frame(width: 800, height: 600)
}
