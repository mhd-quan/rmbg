import SwiftUI

// All glyphs are designed against a 24×24 unit grid with a 2pt safe margin.
// Stroke is applied at the GlyphView layer with `.round` caps/joins so even
// degenerate segments rasterize as dots.

// MARK: - Navigation

struct LibraryGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Three horizontal rules — like the spine labels of stacked books.
        for y: CGFloat in [6.5, 12, 17.5] {
            p.move(to: CGPoint(x: 5, y: y))
            p.addLine(to: CGPoint(x: 19, y: y))
        }
        // A small bullet to the left of each line — book tabs.
        for y: CGFloat in [6.5, 12, 17.5] {
            unitDot(in: &p, at: CGPoint(x: 3.25, y: y))
        }
        return p.applying(unitTransform(in: rect))
    }
}

struct BatchGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Three queued cards stacked top→bottom.
        for y: CGFloat in [3.5, 10.25, 17] {
            unitRoundedRect(in: &p, x: 4, y: y, width: 16, height: 3.5, radius: 1.5)
        }
        return p.applying(unitTransform(in: rect))
    }
}

struct RecentGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Clock face.
        p.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
        // Hands: vertical up + horizontal right (3 o'clock).
        p.move(to: CGPoint(x: 12, y: 12))
        p.addLine(to: CGPoint(x: 12, y: 6))
        p.move(to: CGPoint(x: 12, y: 12))
        p.addLine(to: CGPoint(x: 16, y: 12))
        return p.applying(unitTransform(in: rect))
    }
}

struct SettingsGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Three slider rails.
        for y: CGFloat in [7, 12, 17] {
            p.move(to: CGPoint(x: 4, y: y))
            p.addLine(to: CGPoint(x: 20, y: y))
        }
        // Knobs offset along each rail.
        let knobs: [(CGFloat, CGFloat)] = [(8, 7), (15, 12), (10, 17)]
        for (x, y) in knobs {
            p.addEllipse(in: CGRect(x: x - 1.75, y: y - 1.75, width: 3.5, height: 3.5))
        }
        return p.applying(unitTransform(in: rect))
    }
}

// MARK: - File / image

struct FolderGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Tab + body, drawn as one continuous outline.
        p.move(to: CGPoint(x: 3, y: 7))
        p.addLine(to: CGPoint(x: 3, y: 5))
        p.addLine(to: CGPoint(x: 9, y: 5))
        p.addLine(to: CGPoint(x: 11, y: 7))
        p.addLine(to: CGPoint(x: 21, y: 7))
        p.addLine(to: CGPoint(x: 21, y: 19))
        p.addLine(to: CGPoint(x: 3, y: 19))
        p.closeSubpath()
        return p.applying(unitTransform(in: rect))
    }
}

struct ImageGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Outer frame.
        unitRoundedRect(in: &p, x: 3, y: 5, width: 18, height: 14, radius: 1.5)
        // Sun in the upper-left.
        p.addEllipse(in: CGRect(x: 6.5, y: 8, width: 3, height: 3))
        // Mountain range crossing the lower half.
        p.move(to: CGPoint(x: 4, y: 17))
        p.addLine(to: CGPoint(x: 9, y: 11.5))
        p.addLine(to: CGPoint(x: 13, y: 14.5))
        p.addLine(to: CGPoint(x: 16, y: 12.5))
        p.addLine(to: CGPoint(x: 20, y: 17))
        return p.applying(unitTransform(in: rect))
    }
}

// MARK: - Actions

struct ExportGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Tray (three-sided box, top open).
        p.move(to: CGPoint(x: 3, y: 14))
        p.addLine(to: CGPoint(x: 3, y: 20))
        p.addLine(to: CGPoint(x: 21, y: 20))
        p.addLine(to: CGPoint(x: 21, y: 14))
        // Arrow stem.
        p.move(to: CGPoint(x: 12, y: 14))
        p.addLine(to: CGPoint(x: 12, y: 3))
        // Arrow head.
        p.move(to: CGPoint(x: 7.5, y: 7.5))
        p.addLine(to: CGPoint(x: 12, y: 3))
        p.addLine(to: CGPoint(x: 16.5, y: 7.5))
        return p.applying(unitTransform(in: rect))
    }
}

struct RevealGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Small box anchoring the lower-left.
        p.move(to: CGPoint(x: 11, y: 13))
        p.addLine(to: CGPoint(x: 3, y: 13))
        p.addLine(to: CGPoint(x: 3, y: 21))
        p.addLine(to: CGPoint(x: 13, y: 21))
        p.addLine(to: CGPoint(x: 13, y: 14))
        // Diagonal arrow leaving the box toward upper-right.
        p.move(to: CGPoint(x: 11, y: 13))
        p.addLine(to: CGPoint(x: 21, y: 3))
        // Arrow head.
        p.move(to: CGPoint(x: 15, y: 3))
        p.addLine(to: CGPoint(x: 21, y: 3))
        p.addLine(to: CGPoint(x: 21, y: 9))
        return p.applying(unitTransform(in: rect))
    }
}

struct MoreGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for x: CGFloat in [6, 12, 18] {
            p.addEllipse(in: CGRect(x: x - 0.75, y: 11.25, width: 1.5, height: 1.5))
        }
        return p.applying(unitTransform(in: rect))
    }
}

struct ChevronLeftRightGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Left chevron.
        p.move(to: CGPoint(x: 10.5, y: 7))
        p.addLine(to: CGPoint(x: 6.5, y: 12))
        p.addLine(to: CGPoint(x: 10.5, y: 17))
        // Right chevron.
        p.move(to: CGPoint(x: 13.5, y: 7))
        p.addLine(to: CGPoint(x: 17.5, y: 12))
        p.addLine(to: CGPoint(x: 13.5, y: 17))
        return p.applying(unitTransform(in: rect))
    }
}

// MARK: - State

struct CheckmarkGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 5, y: 12.5))
        p.addLine(to: CGPoint(x: 10, y: 17.5))
        p.addLine(to: CGPoint(x: 19, y: 7.5))
        return p.applying(unitTransform(in: rect))
    }
}

struct WarningGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Triangle, slightly inset to avoid the stroke crowding the edges.
        p.move(to: CGPoint(x: 12, y: 3.5))
        p.addLine(to: CGPoint(x: 21, y: 19.5))
        p.addLine(to: CGPoint(x: 3, y: 19.5))
        p.closeSubpath()
        // Exclamation stem.
        p.move(to: CGPoint(x: 12, y: 9))
        p.addLine(to: CGPoint(x: 12, y: 14.5))
        // Exclamation dot.
        p.addEllipse(in: CGRect(x: 11.25, y: 16.25, width: 1.5, height: 1.5))
        return p.applying(unitTransform(in: rect))
    }
}

// MARK: - Zoom & canvas controls

struct ZoomInGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 3, y: 3, width: 14, height: 14))
        // Handle.
        p.move(to: CGPoint(x: 14.5, y: 14.5))
        p.addLine(to: CGPoint(x: 20.5, y: 20.5))
        // Plus.
        p.move(to: CGPoint(x: 6.5, y: 10))
        p.addLine(to: CGPoint(x: 13.5, y: 10))
        p.move(to: CGPoint(x: 10, y: 6.5))
        p.addLine(to: CGPoint(x: 10, y: 13.5))
        return p.applying(unitTransform(in: rect))
    }
}

struct ZoomOutGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 3, y: 3, width: 14, height: 14))
        p.move(to: CGPoint(x: 14.5, y: 14.5))
        p.addLine(to: CGPoint(x: 20.5, y: 20.5))
        p.move(to: CGPoint(x: 6.5, y: 10))
        p.addLine(to: CGPoint(x: 13.5, y: 10))
        return p.applying(unitTransform(in: rect))
    }
}

struct ZoomFitGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Four L-shaped corner brackets.
        p.move(to: CGPoint(x: 3, y: 8));  p.addLine(to: CGPoint(x: 3, y: 3));  p.addLine(to: CGPoint(x: 8, y: 3))
        p.move(to: CGPoint(x: 16, y: 3)); p.addLine(to: CGPoint(x: 21, y: 3)); p.addLine(to: CGPoint(x: 21, y: 8))
        p.move(to: CGPoint(x: 21, y: 16));p.addLine(to: CGPoint(x: 21, y: 21));p.addLine(to: CGPoint(x: 16, y: 21))
        p.move(to: CGPoint(x: 8, y: 21)); p.addLine(to: CGPoint(x: 3, y: 21)); p.addLine(to: CGPoint(x: 3, y: 16))
        return p.applying(unitTransform(in: rect))
    }
}

struct MaximizeGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Two diagonal outward arrows, top-left and bottom-right.
        p.move(to: CGPoint(x: 4, y: 10)); p.addLine(to: CGPoint(x: 4, y: 4));  p.addLine(to: CGPoint(x: 10, y: 4))
        p.move(to: CGPoint(x: 4, y: 4));  p.addLine(to: CGPoint(x: 10, y: 10))
        p.move(to: CGPoint(x: 14, y: 20));p.addLine(to: CGPoint(x: 20, y: 20));p.addLine(to: CGPoint(x: 20, y: 14))
        p.move(to: CGPoint(x: 20, y: 20));p.addLine(to: CGPoint(x: 14, y: 14))
        return p.applying(unitTransform(in: rect))
    }
}

struct DropZoneGlyph: Glyph {
    init() {}
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Down arrow.
        p.move(to: CGPoint(x: 12, y: 3))
        p.addLine(to: CGPoint(x: 12, y: 15))
        p.move(to: CGPoint(x: 6.5, y: 10))
        p.addLine(to: CGPoint(x: 12, y: 15.5))
        p.addLine(to: CGPoint(x: 17.5, y: 10))
        // Tray.
        p.move(to: CGPoint(x: 3.5, y: 20.5))
        p.addLine(to: CGPoint(x: 20.5, y: 20.5))
        return p.applying(unitTransform(in: rect))
    }
}

// MARK: - Previews

#Preview("All glyphs") {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 12), count: 6),
              spacing: 12) {
        GlyphView<LibraryGlyph>(size: 24)
        GlyphView<BatchGlyph>(size: 24)
        GlyphView<RecentGlyph>(size: 24)
        GlyphView<SettingsGlyph>(size: 24)
        GlyphView<FolderGlyph>(size: 24)
        GlyphView<ImageGlyph>(size: 24)
        GlyphView<ExportGlyph>(size: 24)
        GlyphView<RevealGlyph>(size: 24)
        GlyphView<MoreGlyph>(size: 24)
        GlyphView<ChevronLeftRightGlyph>(size: 24)
        GlyphView<CheckmarkGlyph>(size: 24)
        GlyphView<WarningGlyph>(size: 24)
        GlyphView<ZoomInGlyph>(size: 24)
        GlyphView<ZoomOutGlyph>(size: 24)
        GlyphView<ZoomFitGlyph>(size: 24)
        GlyphView<MaximizeGlyph>(size: 24)
        GlyphView<DropZoneGlyph>(size: 24)
    }
    .padding(24)
    .foregroundStyle(.primary)
}
