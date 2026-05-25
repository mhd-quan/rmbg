import Foundation

/// Bridge between the SwiftUI app and the Python `rmbg-backend` CLI. Each
/// public method maps to one subcommand and parses its JSON response. The
/// bridge keeps a dictionary of in-flight processes so they can be cancelled
/// by job ID.
@MainActor
final class BackendBridge: JobStore.JobRunner {
    let locator: BackendLocator
    private let settings: SettingsStore

    /// Active child processes indexed by the job ID that requested them.
    private var processes: [UUID: Process] = [:]

    /// Job IDs that we explicitly terminated via `cancel(jobID:)`. The
    /// termination handler distinguishes a *user-initiated* cancellation
    /// from a process that died because of a signal (segfault, abort,
    /// OOM-kill, etc.) by checking membership here.
    private var explicitlyTerminated: Set<UUID> = []

    init(locator: BackendLocator, settings: SettingsStore) {
        self.locator = locator
        self.settings = settings
    }

    // MARK: - Read-only commands (Task #6)

    /// Wraps `rmbg-backend auth status --json`.
    func authStatus() async throws -> AuthState {
        let exe = try await locator.resolve()
        return try await runJSON(executable: exe,
                                 args: BackendCommand.authStatus(),
                                 expectZeroExit: false,
                                 decode: AuthState.self)
    }

    /// Wraps `rmbg-backend devices --json`.
    func devices() async throws -> DeviceState {
        let exe = try await locator.resolve()
        return try await runJSON(executable: exe,
                                 args: BackendCommand.devices(),
                                 decode: DeviceState.self)
    }

    /// Wraps `rmbg-backend doctor --json`.
    func doctor() async throws -> DoctorReport {
        let exe = try await locator.resolve()
        return try await runJSON(executable: exe,
                                 args: BackendCommand.doctor(),
                                 expectZeroExit: false,
                                 decode: DoctorReport.self)
    }

    /// Wraps `rmbg-backend warmup ... --json`. Returns a `WarmupPayload` for
    /// callers that want the resolved device; most callers ignore the return.
    @discardableResult
    func warmup() async throws -> WarmupPayload {
        let exe = try await locator.resolve()
        return try await runJSON(executable: exe,
                                 args: BackendCommand.warmup(device: settings.device),
                                 decode: WarmupPayload.self)
    }

    // MARK: - JobRunner conformance (filled by later tasks)

    func runSingle(input: URL,
                   options: ExportRequest,
                   jobID: UUID) async throws -> BackendResult {
        let exe = try await locator.resolve()
        let response: SingleResponse = try await runJSON(
            executable: exe,
            args: BackendCommand.single(input: input, options: options),
            jobID: jobID,
            decode: SingleResponse.self
        )
        return response.result
    }

    func runBatch(inputs: [URL],
                  options: ExportRequest,
                  jobID: UUID,
                  onProgress: @escaping @MainActor @Sendable (ProgressLine) -> Void) async throws -> BatchSummary {
        let exe = try await locator.resolve()
        let args = BackendCommand.batch(inputs: inputs, options: options)
        let env = backendEnvironment()

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = exe
            process.arguments = args
            process.environment = env
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            let state = BatchRunState()
            let stdoutHandle = stdoutPipe.fileHandleForReading
            let stderrHandle = stderrPipe.fileHandleForReading

            stdoutHandle.readabilityHandler = { fh in
                let chunk = fh.availableData
                if chunk.isEmpty {
                    fh.readabilityHandler = nil
                    return
                }
                state.appendStdout(chunk) { event in
                    switch event {
                    case .progress(let line):
                        Task { @MainActor in onProgress(line) }
                    case .summary(let summary):
                        state.recordSummary(summary)
                    }
                }
            }

            stderrHandle.readabilityHandler = { fh in
                let chunk = fh.availableData
                if chunk.isEmpty {
                    fh.readabilityHandler = nil
                    return
                }
                state.appendStderr(chunk)
            }

            process.terminationHandler = { [weak self] proc in
                stdoutHandle.readabilityHandler = nil
                stderrHandle.readabilityHandler = nil
                // Drain residual bytes from the pipes (the final summary line
                // can land here if the buffer hasn't flushed yet).
                if let remaining = try? stdoutHandle.readToEnd(), !remaining.isEmpty {
                    state.appendStdout(remaining) { event in
                        if case .summary(let summary) = event {
                            state.recordSummary(summary)
                        }
                    }
                }
                if let remaining = try? stderrHandle.readToEnd(), !remaining.isEmpty {
                    state.appendStderr(remaining)
                }

                Task { @MainActor in self?.processes.removeValue(forKey: jobID) }

                if proc.terminationReason == .uncaughtSignal {
                    continuation.resume(throwing: BackendError.cancelled)
                } else if let summary = state.finalSummary {
                    continuation.resume(returning: summary)
                } else if proc.terminationStatus == 0 {
                    continuation.resume(throwing: BackendError.decode(
                        message: "Backend exited without emitting a summary line."
                    ))
                } else {
                    continuation.resume(throwing: BackendError.nonZeroExit(
                        code: proc.terminationStatus,
                        stderr: state.stderrString
                    ))
                }
            }

            processes[jobID] = process

            do {
                try process.run()
            } catch {
                processes.removeValue(forKey: jobID)
                continuation.resume(throwing: error)
            }
        }
    }

    func cancel(jobID: UUID) async {
        explicitlyTerminated.insert(jobID)
        terminateProcess(for: jobID)
    }

    private func terminateProcess(for jobID: UUID) {
        guard let process = processes[jobID] else { return }
        if process.isRunning {
            process.terminate()
        }
        processes.removeValue(forKey: jobID)
    }

    // MARK: - Process plumbing

    /// Spawn a one-shot subprocess that writes a single JSON object to stdout,
    /// wait for it to exit, and decode the response. Some backend commands
    /// (auth, doctor) emit JSON even when they return non-zero; pass
    /// `expectZeroExit: false` for those.
    fileprivate func runJSON<T: Decodable>(
        executable: URL,
        args: [String],
        expectZeroExit: Bool = true,
        jobID: UUID? = nil,
        decode type: T.Type
    ) async throws -> T {
        let env = backendEnvironment()
        AppLog.backend.debug("spawn: \(executable.path) \(args.joined(separator: " "))")
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = args
            process.environment = env
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { [weak self] proc in
                let stdoutData = (try? stdout.fileHandleForReading.readToEnd()) ?? Data()
                let stderrData = (try? stderr.fileHandleForReading.readToEnd()) ?? Data()
                let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
                let terminationReason = proc.terminationReason
                let exitCode = proc.terminationStatus

                Task { @MainActor [weak self] in
                    let wasExplicitlyCancelled: Bool
                    if let jobID, let self {
                        wasExplicitlyCancelled = self.explicitlyTerminated.remove(jobID) != nil
                        self.processes.removeValue(forKey: jobID)
                    } else {
                        wasExplicitlyCancelled = false
                    }

                    if terminationReason == .uncaughtSignal {
                        if wasExplicitlyCancelled {
                            continuation.resume(throwing: BackendError.cancelled)
                        } else {
                            let augmented = stderrString.isEmpty
                                ? "Backend was killed by signal (status \(exitCode)). The Python process may have segfaulted or been killed by the system (e.g. for memory pressure)."
                                : stderrString
                            continuation.resume(throwing: BackendError.nonZeroExit(
                                code: exitCode,
                                stderr: augmented
                            ))
                        }
                        return
                    }
                    let exitOK = exitCode == 0 || !expectZeroExit
                    guard exitOK else {
                        continuation.resume(throwing: BackendError.nonZeroExit(
                            code: exitCode,
                            stderr: stderrString
                        ))
                        return
                    }
                    do {
                        let value = try JSONDecoder.rmbg.decode(T.self, from: stdoutData)
                        continuation.resume(returning: value)
                    } catch {
                        let preview = String(data: stdoutData, encoding: .utf8)?.prefix(200) ?? ""
                        AppLog.backend.error("Decode failed: \(error.localizedDescription); stdout=\(preview)")
                        continuation.resume(throwing: BackendError.decode(
                            message: "\(error.localizedDescription)\n— stderr:\n\(stderrString)"
                        ))
                    }
                }
            }

            if let jobID { processes[jobID] = process }

            do {
                try process.run()
            } catch {
                if let jobID { processes.removeValue(forKey: jobID) }
                continuation.resume(throwing: error)
            }
        }
    }

    /// Construct the env dict passed to the child process. We forward the
    /// parent env and overlay `HF_HOME` based on Settings or the dev repo.
    fileprivate func backendEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PYTHONIOENCODING"] = "utf-8"
        if let override = settings.hfHomeOverride {
            env["HF_HOME"] = override.path
        } else if let root = Bundle.main.object(forInfoDictionaryKey: "RmbgDevRepoRoot") as? String {
            let candidate = URL(fileURLWithPath: root).appendingPathComponent(".hf_home")
            if FileManager.default.fileExists(atPath: candidate.path) {
                env["HF_HOME"] = candidate.path
            }
        }
        return env
    }
}
