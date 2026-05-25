import Foundation

/// Mutable bookkeeping for a single batch invocation. The
/// `terminationHandler` and the two `readabilityHandler`s share this state
/// via a serial queue so they don't race on the underlying buffers.
final class BatchRunState: @unchecked Sendable {
    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    private var _finalSummary: BatchSummary?
    private let queue = DispatchQueue(label: "rmbg.batch.runstate")

    /// The last `{type: "summary"}` line that arrived, if any. Reading this
    /// is thread-safe — synchronized through the queue.
    var finalSummary: BatchSummary? {
        queue.sync { _finalSummary }
    }

    /// All of stderr so far, decoded as UTF-8. Used to populate
    /// `BackendError.nonZeroExit`.
    var stderrString: String {
        queue.sync { String(data: stderrBuffer, encoding: .utf8) ?? "" }
    }

    func recordSummary(_ summary: BatchSummary) {
        queue.sync { _finalSummary = summary }
    }

    func appendStdout(_ chunk: Data, emit: (BatchEvent) -> Void) {
        queue.sync {
            stdoutBuffer.append(chunk)
            while let newline = stdoutBuffer.firstIndex(of: 0x0a) {
                let lineData = stdoutBuffer.subdata(in: stdoutBuffer.startIndex..<newline)
                stdoutBuffer.removeSubrange(stdoutBuffer.startIndex...newline)
                guard !lineData.isEmpty else { continue }
                if let event = try? JSONDecoder.rmbg.decode(BatchEvent.self, from: lineData) {
                    emit(event)
                } else {
                    let preview = String(data: lineData, encoding: .utf8) ?? ""
                    AppLog.backend.error("batch line decode failed: \(preview.prefix(200))")
                }
            }
        }
    }

    func appendStderr(_ chunk: Data) {
        queue.sync { stderrBuffer.append(chunk) }
    }
}
