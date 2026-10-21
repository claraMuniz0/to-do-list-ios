import SwiftUI

/// Palette for illustration dots, kept apart from `ChipPalette` because the two evolve independently.
enum IllustrationDotColor: Equatable {
    case coral, green, peach, blue

    var color: Color {
        switch self {
        case .coral: DSColor.accent
        case .green: DSColor.illustrationGreen
        case .peach: DSColor.illustrationPeach
        case .blue: DSColor.illustrationBlue
        }
    }
}

/// A decorative confetti piece; `x`/`y` are its top-left corner in canvas coordinates.
/// A piece with a `barSize` is a small rounded bar instead of a dot.
struct IllustrationDot: Equatable {
    let color: IllustrationDotColor
    let x: CGFloat
    let y: CGFloat
    let diameter: CGFloat
    let barSize: CGSize?

    init(color: IllustrationDotColor, x: CGFloat, y: CGFloat, diameter: CGFloat = 0, barSize: CGSize? = nil) {
        self.color = color
        self.x = x
        self.y = y
        self.diameter = diameter
        self.barSize = barSize
    }
}

/// Geometry of one illustration. The design draws three sizes (Welcome, All Done, No Results),
/// so geometry is data and the view stays a single component.
struct EmptyStateIllustrationLayout: Equatable {
    let canvas: CGFloat
    let halo: CGFloat
    let disc: CGFloat
    let symbolSize: CGFloat
    let dots: [IllustrationDot]

    static let welcome = EmptyStateIllustrationLayout(
        canvas: 240, halo: 200, disc: 140, symbolSize: 64,
        dots: [
            IllustrationDot(color: .coral, x: 192, y: 28, diameter: 28),
            IllustrationDot(color: .green, x: 22, y: 186, diameter: 18),
            IllustrationDot(color: .peach, x: 204, y: 176, diameter: 20),
            IllustrationDot(color: .blue, x: 10, y: 60, diameter: 12),
        ]
    )

    static let celebration = EmptyStateIllustrationLayout(
        canvas: 200, halo: 200, disc: 120, symbolSize: 64,
        // The design's ochre dot has no illustration color token yet, so it is drawn coral.
        dots: [
            IllustrationDot(color: .coral, x: 22, y: 40, diameter: 12),
            IllustrationDot(color: .green, x: 166, y: 52, diameter: 14),
            IllustrationDot(color: .peach, x: 8, y: 118, barSize: CGSize(width: 17, height: 13)),
            IllustrationDot(color: .blue, x: 173, y: 138, barSize: CGSize(width: 17, height: 14)),
            IllustrationDot(color: .coral, x: 150, y: 12, diameter: 10),
            IllustrationDot(color: .blue, x: 52, y: 172, diameter: 10),
            IllustrationDot(color: .green, x: 118, y: 173, barSize: CGSize(width: 15, height: 10)),
        ]
    )

    static let noResults = EmptyStateIllustrationLayout(
        canvas: 140, halo: 140, disc: 90, symbolSize: 48,
        dots: [
            IllustrationDot(color: .coral, x: 112, y: 10, diameter: 18),
            IllustrationDot(color: .peach, x: 8, y: 108, diameter: 14),
        ]
    )
}

/// Decorative only: hidden from VoiceOver, so the surrounding screen must carry the meaning in its own text.
struct EmptyStateIllustration: View {
    let symbol: String
    let layout: EmptyStateIllustrationLayout

    init(symbol: String, layout: EmptyStateIllustrationLayout = .welcome) {
        self.symbol = symbol
        self.layout = layout
    }

    var body: some View {
        ZStack {
            Circle().fill(DSColor.accentSoft).frame(width: layout.halo, height: layout.halo)
            Circle().fill(DSColor.surface).frame(width: layout.disc, height: layout.disc)
                .dsShadow(.illustration)
            Image(systemName: symbol)
                .font(.system(size: layout.symbolSize))
                .foregroundStyle(DSColor.accent)
            ForEach(Array(layout.dots.enumerated()), id: \.offset) { _, dot in
                piece(dot)
            }
        }
        .frame(width: layout.canvas, height: layout.canvas)
        .accessibilityHidden(true)
    }
}

extension EmptyStateIllustration {
    @ViewBuilder fileprivate func piece(_ dot: IllustrationDot) -> some View {
        if let bar = dot.barSize {
            RoundedRectangle(cornerRadius: 3).fill(dot.color.color)
                .frame(width: bar.width, height: bar.height)
                .position(x: dot.x + bar.width / 2, y: dot.y + bar.height / 2)
        } else {
            Circle().fill(dot.color.color)
                .frame(width: dot.diameter, height: dot.diameter)
                .position(x: dot.x + dot.diameter / 2, y: dot.y + dot.diameter / 2)
        }
    }
}

#if DEBUG
#Preview("Welcome") { EmptyStateIllustration(symbol: "list.clipboard", layout: .welcome) }
#Preview("All done") { EmptyStateIllustration(symbol: "party.popper", layout: .celebration) }
#Preview("No results") { EmptyStateIllustration(symbol: "magnifyingglass", layout: .noResults) }
#endif
