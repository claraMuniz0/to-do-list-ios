import SwiftUI

/// Corner radii. `pill` is deliberately huge so any height renders fully rounded.
enum DSRadius {
    static let md: CGFloat = 16
    static let pill: CGFloat = 999
}

/// Visual sizes vs. hit areas: interactive controls keep at least `minimum` points to tap.
enum DSTouchTarget {
    static let minimum: CGFloat = 44
    /// Visual size of the options icon frame; the hit area is still padded up to `minimum`.
    static let moreOptions: CGFloat = 40
    /// Drawn ring size of the task checkbox; the tappable frame is `minimum`.
    static let checkboxRing: CGFloat = 26
}

/// A hard-edged offset shadow (radius 0) matches the design's flat look; only illustration and toast are blurred.
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

    /// Applies the shadow without horizontal offset, as no design token uses one.
    func dsShadow(_ shadow: DSShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
