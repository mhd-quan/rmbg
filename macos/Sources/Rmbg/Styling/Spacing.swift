import CoreGraphics

/// Generous Things 3-style spacing scale. All values are in points.
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    /// Corner radii used across the app. Things 3 prefers ~8pt for cards,
    /// ~6pt for chips, ~4pt for status dots, 999pt for capsules.
    enum Radius {
        static let xs: CGFloat = 4
        static let s: CGFloat = 6
        static let m: CGFloat = 8
        static let l: CGFloat = 12
        static let xl: CGFloat = 18
        static let capsule: CGFloat = 999
    }

    /// Hairline stroke widths.
    enum Line {
        static let hairline: CGFloat = 1
        static let medium: CGFloat = 1.5
        static let thick: CGFloat = 2
    }
}
