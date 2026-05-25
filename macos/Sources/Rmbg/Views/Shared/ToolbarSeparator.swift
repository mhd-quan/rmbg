import SwiftUI

/// 1pt hairline used between content sections (e.g. inspector strips).
struct ToolbarSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Palette.border)
            .frame(height: 1)
    }
}
