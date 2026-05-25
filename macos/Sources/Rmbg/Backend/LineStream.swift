import Foundation

/// Async sequence of newline-delimited strings read from a `FileHandle`.
/// Uses `FileHandle.readabilityHandler` so reads happen on a background
/// dispatch queue and the producing process is consumed lazily.
///
/// Lines are returned without their trailing newline. EOF is signalled by
/// the iterator returning `nil`. If the FileHandle is closed externally
/// (e.g. on cancellation) the iterator finishes gracefully.
struct LineStream: AsyncSequence {
    typealias Element = String

    let handle: FileHandle

    func makeAsyncIterator() -> AsyncStream<String>.AsyncIterator {
        let stream = AsyncStream<String> { continuation in
            let state = StreamState()
            handle.readabilityHandler = { fh in
                let chunk = fh.availableData
                if chunk.isEmpty {
                    state.flush { line in continuation.yield(line) }
                    fh.readabilityHandler = nil
                    continuation.finish()
                    return
                }
                state.append(chunk) { line in continuation.yield(line) }
            }
            continuation.onTermination = { [weak handle] _ in
                handle?.readabilityHandler = nil
            }
        }
        return stream.makeAsyncIterator()
    }

    /// Mutable line-buffer state. A reference type so the closures sharing
    /// it all see the same mutations without box-style capture games.
    private final class StreamState: @unchecked Sendable {
        private var buffer = Data()
        private let queue = DispatchQueue(label: "rmbg.linestream")

        func append(_ chunk: Data, emit: (String) -> Void) {
            queue.sync {
                buffer.append(chunk)
                while let newline = buffer.firstIndex(of: 0x0a) {
                    let lineData = buffer.subdata(in: buffer.startIndex..<newline)
                    buffer.removeSubrange(buffer.startIndex...newline)
                    guard !lineData.isEmpty,
                          let line = String(data: lineData, encoding: .utf8) else { continue }
                    emit(line)
                }
            }
        }

        func flush(emit: (String) -> Void) {
            queue.sync {
                guard !buffer.isEmpty,
                      let line = String(data: buffer, encoding: .utf8) else { return }
                emit(line)
                buffer.removeAll()
            }
        }
    }
}
