import SwiftUI

/// Compact metadata strip pinned to the bottom of the single detail view.
/// Shows filename, dimensions, duration, and the resolved device used for
/// the run. The layout collapses gracefully on narrow widths via
/// `ViewThatFits` — first try the full horizontal row, then a 2×2 grid,
/// then a vertical stack.
struct DetailMetadataStrip: View {
    let result: BackendResult?
    let job: ImageJob?

    var body: some View {
        VStack(spacing: 0) {
            ToolbarSeparator()
            content
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)
                .background(Palette.surface.opacity(0.55))
        }
    }

    @ViewBuilder
    private var content: some View {
        ViewThatFits(in: .horizontal) {
            horizontalRow
            wrappedGrid
        }
    }

    /// Single-line layout used when the column is wide enough.
    private var horizontalRow: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            ForEach(cells) { cell in
                metadataCell(cell)
                    .layoutPriority(cell.priority)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 2-column grid used when the row doesn't fit.
    private var wrappedGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.l, verticalSpacing: Spacing.s) {
            GridRow {
                metadataCell(cells[0])
                metadataCell(cells[1])
            }
            GridRow {
                metadataCell(cells[2])
                metadataCell(cells[3])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataCell(_ cell: Cell) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(cell.label)
                .appFont(.caption)
                .foregroundStyle(Palette.textTertiary)
                .lineLimit(1)
            Text(cell.value)
                .appFont(cell.isMono ? .monoSmall : .bodyEmphasized)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(cell.value)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct Cell: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let isMono: Bool
        let priority: Double
    }

    private var cells: [Cell] {
        [
            Cell(label: "File",       value: filenameText,   isMono: false, priority: 0.5),
            Cell(label: "Dimensions", value: dimensionsText, isMono: true,  priority: 1),
            Cell(label: "Duration",   value: durationText,   isMono: true,  priority: 1),
            Cell(label: "Device",     value: deviceText,     isMono: true,  priority: 1),
        ]
    }

    private var filenameText: String {
        if let result { return URL(fileURLWithPath: result.inputPath).lastPathComponent }
        if let job, case .single(let url) = job.kind { return url.lastPathComponent }
        return "—"
    }

    private var dimensionsText: String {
        guard let result else { return "—" }
        return "\(result.width) × \(result.height)"
    }

    private var durationText: String {
        guard let result else { return "—" }
        if result.durationSeconds < 1 {
            return String(format: "%.0f ms", result.durationSeconds * 1000)
        }
        if result.durationSeconds < 60 {
            return String(format: "%.2f s", result.durationSeconds)
        }
        let minutes = Int(result.durationSeconds) / 60
        let seconds = Int(result.durationSeconds) % 60
        return "\(minutes)m \(seconds)s"
    }

    private var deviceText: String {
        job?.exportRequest.device.displayName ?? "—"
    }
}

#Preview("Wide") {
    DetailMetadataStrip(result: .preview(), job: ImageJob.previewSingle())
        .frame(width: 700)
}

#Preview("Narrow") {
    DetailMetadataStrip(result: .preview(), job: ImageJob.previewSingle())
        .frame(width: 320)
}
