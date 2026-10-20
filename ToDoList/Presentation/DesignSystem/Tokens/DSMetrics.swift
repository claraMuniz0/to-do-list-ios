import SwiftUI

enum DSRadius {
    static let md: CGFloat = 16
    static let pill: CGFloat = 999
}

/// Visual sizes vs. hit areas: interactive controls keep at least `minimum` points to tap.
enum DSTouchTarget {
    static let minimum: CGFloat = 44
    static let moreOptions: CGFloat = 40
    static let checkboxRing: CGFloat = 26
}

struct DSShadow: Equatable {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    static let soft = DSShadow(color: DSColor.shadowSoft, radius: 0, y: 3)
    static let accent = DSShadow(color: DSColor.shadowAccent, radius: 0, y: 4)
    static let accentSmall = DSShadow(color: DSColor.shadowAccent, radius: 0, y: 3)
    static let illustration = DSShadow(color: DSColor.illustrationShadow, radius: 24, y: 8)
    static let toast = DSShadow(color: DSColor.toastShadow, radius: 20, y: 6)
}

extension View {
    /// Fills `shape` behind the view and casts `shadow` from that shape only, so the content
    /// (text, icons) never gets a shadow of its own.
    func dsBackground<S: Shape>(_ fill: Color, in shape: S, shadow: DSShadow = .none) -> some View {
        background { shape.fill(fill).dsShadow(shadow) }
    }

    func dsShadow(_ shadow: DSShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
