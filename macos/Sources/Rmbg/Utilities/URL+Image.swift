import AppKit
import Foundation
import ImageIO

/// Type-erased Sendable wrapper for `NSImage`. Used to hand off images
/// across actor boundaries — we keep ownership semantics simple (the
/// producer hands off, the consumer takes over).
struct SendableImage: @unchecked Sendable {
    let image: NSImage
}

/// Small thumbnail cache so the same image isn't decoded twice as the user
/// scrolls. Backed by `NSCache` for automatic memory pressure eviction.
@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 256
    }

    func thumbnail(for url: URL, maxPixelSize: CGFloat = 512) async -> NSImage? {
        let key = "\(url.path)|\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let wrapped: SendableImage? = await Task.detached(priority: .utility) {
            ThumbnailCache.makeThumbnail(url: url, maxPixelSize: maxPixelSize)
                .map { SendableImage(image: $0) }
        }.value
        if let image = wrapped?.image {
            cache.setObject(image, forKey: key)
            return image
        }
        return nil
    }

    nonisolated static func makeThumbnail(url: URL, maxPixelSize: CGFloat) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

extension URL {
    /// True if the file extension matches an image type supported by the
    /// backend (`src/rmbg_backend/paths.py`).
    var isSupportedImageExtension: Bool {
        Self.supportedImageExtensions.contains(pathExtension.lowercased())
    }

    static let supportedImageExtensions: Set<String> = [
        "bmp", "heic", "heif", "jpeg", "jpg", "png", "tif", "tiff", "webp",
    ]
}
