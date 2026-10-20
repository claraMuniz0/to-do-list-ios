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

/// A decorative dot; `x`/`y` are its top-left corner in canvas coordinates.
struct IllustrationDot: Equatable {
    let color: IllustrationDotColor
    let x: CGFloat
    let y: CGFloat
    let diameter: CGFloat
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
        dots: [IllustrationDot(color: .blue, x: 52, y: 172, diameter: 10)]
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
                Circle().fill(dot.color.color)
                    .frame(width: dot.diameter, height: dot.diameter)
                    .position(x: dot.x + dot.diameter / 2, y: dot.y + dot.diameter / 2)
            }
        }
        .frame(width: layout.canvas, height: layout.canvas)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Welcome") { EmptyStateIllustration(symbol: "list.clipboard", layout: .welcome) }
#Preview("All done") { EmptyStateIllustration(symbol: "party.popper", layout: .celebration) }
#Preview("No results") { EmptyStateIllustration(symbol: "magnifyingglass", layout: .noResults) }
#endif
