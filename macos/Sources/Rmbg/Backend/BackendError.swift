import Foundation

/// Errors surfaced by the backend bridge. Each case maps to a specific
/// failure mode; `LocalizedError` makes them presentable through
/// `error.localizedDescription`.
enum BackendError: LocalizedError, Equatable {
    case notFound
    case nonZeroExit(code: Int32, stderr: String)
    case decode(message: String)
    case cancelled
    case invalidInput(String)
    case unauthenticated(String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Could not locate the rmbg-backend executable. Pick it manually in Settings → Backend."
        case .nonZeroExit(let code, let stderr):
            let cleaned = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty
                ? "Backend exited with code \(code)."
                : "Backend exited with code \(code):\n\(cleaned)"
        case .decode(let message):
            return "Could not parse the backend response: \(message)"
        case .cancelled:
            return "Job cancelled."
        case .invalidInput(let message):
            return message
        case .unauthenticated(let message):
            return message
        case .notImplemented:
            return "This backend operation is not yet implemented."
        }
    }
}
