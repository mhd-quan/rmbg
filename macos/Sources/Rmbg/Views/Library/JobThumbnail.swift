import AppKit
import SwiftUI

/// Lazy-loaded thumbnail. Renders a colored placeholder until the image
/// finishes decoding on a background queue.
struct JobThumbnail: View {
    let url: URL?
    var maxPixelSize: CGFloat = 512
    var cornerRadius: CGFloat = Spacing.Radius.m
    var aspect: ContentMode = .fill

    @State private var image: NSImage?
    @State private var loadToken = UUID()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(placeholderGradient)
                .overlay {
                    if image == nil {
                        GlyphView<ImageGlyph>(size: 24, lineWidth: 1)
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: aspect)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .task(id: url) { await load() }
    }

    @MainActor
    private func load() async {
        let target = url
        guard let target else { image = nil; return }
        image = await ThumbnailCache.shared.thumbnail(for: target, maxPixelSize: maxPixelSize)
    }

    private var placeholderGradient: LinearGradient {
        let hash = abs((url?.path.hashValue ?? 0) % 360)
        let hue = Double(hash) / 360.0
        let top = Color(hue: hue, saturation: 0.18, brightness: 0.92)
        let bottom = Color(hue: hue, saturation: 0.28, brightness: 0.78)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    JobThumbnail(url: nil)
        .frame(width: 200, height: 140)
        .padding(20)
}
