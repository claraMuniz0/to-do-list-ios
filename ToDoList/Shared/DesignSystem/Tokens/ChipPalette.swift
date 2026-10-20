import SwiftUI

/// Chip color pairs keyed by palette color. Violet, ochre and teal arrive with custom categories.
enum ChipPalette: Equatable, CaseIterable {
    case blue, brick, green

    /// Maps a `Category.colorKey` to a palette. Seeded categories use their own id as key
    /// (work/personal/shopping); unknown keys fall back to `.brick` so a chip never renders unstyled.
    init(colorKey: String) {
        switch colorKey.lowercased() {
        case "work", "blue": self = .blue
        case "personal", "brick": self = .brick
        case "shopping", "green": self = .green
        default: self = .brick
        }
    }

    var background: Color {
        switch self {
        case .blue: Color("chip-blue-bg")
        case .brick: Color("chip-brick-bg")
        case .green: Color("chip-green-bg")
        }
    }

    var foreground: Color {
        switch self {
        case .blue: Color("chip-blue-fg")
        case .brick: Color("chip-brick-fg")
        case .green: Color("chip-green-fg")
        }
    }
}
