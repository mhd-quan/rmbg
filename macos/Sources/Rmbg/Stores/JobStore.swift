import AppKit
import Foundation
import Observation

/// Container + orchestrator for all jobs. Owns the array of `ImageJob`s and
/// the closures that drive each job through the backend. The closures are
/// injected at `RmbgApp` initialization so previews and tests can substitute
/// no-op implementations.
@MainActor
@Observable
final class JobStore {
    private(set) var jobs: [ImageJob] = []

    @ObservationIgnored let recents: RecentsStore
    @ObservationIgnored let settings: SettingsStore
    @ObservationIgnored let banners: BannerCenter
    @ObservationIgnored private let runner: JobRunner?

    /// Abstracted backend surface so previews can supply a stub.
    @MainActor
    protocol JobRunner: AnyObject {
        func runSingle(input: URL,
                       options: ExportRequest,
                       jobID: UUID) async throws -> BackendResult
        func runBatch(inputs: [URL],
                      options: ExportRequest,
                      jobID: UUID,
                      onProgress: @escaping @MainActor @Sendable (ProgressLine) -> Void) async throws -> BatchSummary
        func cancel(jobID: UUID) async
    }

    init(runner: JobRunner?,
         recents: RecentsStore,
         settings: SettingsStore,
         banners: BannerCenter) {
        self.runner = runner
        self.recents = recents
        self.settings = settings
        self.banners = banners
    }

    // MARK: - Queries

    func job(for id: UUID) -> ImageJob? { jobs.first { $0.id == id } }

    var libraryJobs: [ImageJob] {
        jobs.filter {
            if case .single = $0.kind { return true }
            return false
        }
    }

    var batchJobs: [ImageJob] {
        jobs.filter {
            if case .batch = $0.kind { return true }
            return false
        }
    }

    var activeJobs: [ImageJob] { jobs.filter { $0.status.isRunning } }

    // MARK: - Add work

    @discardableResult
    func startSingle(_ url: URL) -> ImageJob {
        let job = ImageJob(kind: .single(url),
                           exportRequest: settings.currentExportRequest())
        jobs.insert(job, at: 0)
        Task { await runSingle(job) }
        return job
    }

    @discardableResult
    func startBatch(_ urls: [URL]) -> ImageJob {
        let job = ImageJob(kind: .batch(urls),
                           exportRequest: settings.currentExportRequest())
        jobs.insert(job, at: 0)
        Task { await runBatch(job) }
        return job
    }

    /// Reroute incoming URLs to either single or batch based on count.
    @discardableResult
    func ingest(_ urls: [URL]) -> ImageJob? {
        guard !urls.isEmpty else { return nil }
        if urls.count == 1 { return startSingle(urls[0]) }
        return startBatch(urls)
    }

    // MARK: - Job control

    func cancel(_ job: ImageJob) {
        guard job.status.isRunning else { return }
        Task {
            await runner?.cancel(jobID: job.id)
            job.status = .cancelled
        }
    }

    func remove(_ job: ImageJob) {
        if job.status.isRunning { cancel(job) }
        jobs.removeAll { $0.id == job.id }
    }

    func retry(_ job: ImageJob) {
        guard job.status.isTerminal else { return }
        job.status = .pending
        job.error = nil
        switch job.kind {
        case .single: Task { await runSingle(job) }
        case .batch: Task { await runBatch(job) }
        }
    }

    // MARK: - Backend drivers

    private func runSingle(_ job: ImageJob) async {
        guard let runner else {
            job.status = .failed(message: "Backend bridge is unavailable.")
            return
        }
        guard case let .single(url) = job.kind else { return }
        job.status = .warming
        // The first call after launch loads the model — show .warming so the
        // sidebar footer + the row state reflect that. Once warmed, the
        // backend returns quickly so subsequent jobs jump straight to
        // .processing.
        do {
            try ensureOutputDirectory(job.exportRequest.outputDirectory)
            job.status = .processing(progress: 0)
            let result = try await runner.runSingle(input: url,
                                                    options: job.exportRequest,
                                                    jobID: job.id)
            job.singleResult = result
            job.status = .succeeded
            recents.add(result)
            if settings.revealAfterExport, let revealed = result.previewURL ?? Optional(result.outputURL) {
                NSWorkspace.shared.activateFileViewerSelecting([revealed])
            }
        } catch is CancellationError {
            job.status = .cancelled
        } catch {
            job.status = .failed(message: error.localizedDescription)
            job.error = error.localizedDescription
            banners.post(.error, "Background removal failed", error.localizedDescription)
        }
    }

    private func runBatch(_ job: ImageJob) async {
        guard let runner else {
            job.status = .failed(message: "Backend bridge is unavailable.")
            return
        }
        guard case let .batch(urls) = job.kind else { return }
        do {
            try ensureOutputDirectory(job.exportRequest.outputDirectory)
            job.status = .partial(done: 0, total: urls.count)
            let summary = try await runner.runBatch(
                inputs: urls,
                options: job.exportRequest,
                jobID: job.id,
                onProgress: { [weak job] line in
                    guard let job else { return }
                    if let item = line.item { job.batchResults.append(item) }
                    job.status = .partial(done: line.done, total: line.total)
                }
            )
            job.batchSummary = summary
            job.status = summary.failed > 0
                ? .failed(message: "\(summary.failed) of \(summary.total) failed.")
                : .succeeded
            for item in summary.results {
                if let result = item.result {
                    recents.add(result)
                }
            }
        } catch is CancellationError {
            job.status = .cancelled
        } catch {
            job.status = .failed(message: error.localizedDescription)
            job.error = error.localizedDescription
            banners.post(.error, "Batch failed", error.localizedDescription)
        }
    }

    private func ensureOutputDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url,
                                                withIntermediateDirectories: true)
    }
}

extension JobStore {
    /// Preview-friendly store seeded with a mix of finished and in-progress
    /// jobs. The runner is nil — startSingle/startBatch will fail gracefully
    /// (status = .failed), which is fine for previews that only render.
    static func preview(seeded: Bool = true) -> JobStore {
        let recents = RecentsStore.preview()
        let settings = SettingsStore.preview()
        let banners = BannerCenter.preview()
        let store = JobStore(runner: nil, recents: recents, settings: settings, banners: banners)
        if seeded {
            store.jobs = [
                .previewSingle(named: "lighthouse.jpg", status: .succeeded),
                .previewSingle(named: "robot.png", status: .processing(progress: 0.4)),
                .previewBatch(count: 12),
                .previewSingle(named: "sunset.jpg", status: .succeeded),
            ]
        }
        return store
    }
}
