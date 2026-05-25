import Foundation

/// JSON payloads emitted by the backend CLI that don't already have a model
/// type in `Models/`. Decoded with `.convertFromSnakeCase`.

struct WarmupPayload: Decodable {
    let type: String
    let modelId: String
    let device: String
    let loaded: Bool
}

struct DoctorReport: Decodable {
    let ok: Bool
    let checks: [Check]
    let python: String
    let platform: String
    let machine: String
    let executable: String
    let modelId: String
    let autoDevice: String

    struct Check: Decodable, Identifiable {
        let name: String
        let status: String        // "ok" | "warning" | "error"
        let message: String

        var id: String { name }
        var isError: Bool { status.lowercased() == "error" }
        var isWarning: Bool { status.lowercased() == "warning" }
    }
}

/// Wrapper for `single --json` responses. Backend emits `{type: "single",
/// result: { ... }}`.
struct SingleResponse: Decodable {
    let type: String
    let result: BackendResult
}

/// Discriminated union for `batch --json-lines`. Each line is either a
/// progress tick or the final summary.
enum BatchEvent: Decodable {
    case progress(ProgressLine)
    case summary(BatchSummary)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "progress":
            self = .progress(try ProgressLine(from: decoder))
        case "summary":
            self = .summary(try BatchSummary(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown batch event type: \(type)"
            )
        }
    }
}

/// Shared decoder that matches the backend's JSON dialect.
extension JSONDecoder {
    static var rmbg: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
