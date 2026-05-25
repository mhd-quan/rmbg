import SwiftUI

/// Small colored circle that maps to `ImageJobStatus`. Used in sidebar rows
/// and batch queue rows.
struct StatusDot: View {
    var status: ImageJobStatus
    var diameter: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .overlay {
                if case .processing = status {
                    Circle()
                        .stroke(color.opacity(0.4), lineWidth: 1)
                        .scaleEffect(1.6)
                        .opacity(0.6)
                        .blendMode(.plusLighter)
                }
            }
            .accessibilityLabel(accessibilityLabel)
    }

    private var color: Color {
        switch status {
        case .pending: return Palette.Status.pending
        case .warming, .processing, .partial: return Palette.Status.processing
        case .succeeded: return Palette.Status.success
        case .failed: return Palette.Status.failure
        case .cancelled: return Palette.Status.cancelled
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .pending: return "Pending"
        case .warming: return "Warming"
        case .processing: return "Processing"
        case .partial(let done, let total): return "\(done) of \(total)"
        case .succeeded: return "Succeeded"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(Array([
            ImageJobStatus.pending,
            .warming,
            .processing(progress: 0.4),
            .partial(done: 3, total: 8),
            .succeeded,
            .failed(message: "oops"),
            .cancelled,
        ].enumerated()), id: \.offset) { _, status in
            HStack { StatusDot(status: status); Text(String(describing: status)).appFont(.body) }
        }
    }
    .padding(24)
}
