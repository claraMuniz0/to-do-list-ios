import SwiftUI

enum SplashDotColor: Equatable {
    case cream, soft, dark

    var color: Color {
        switch self {
        case .cream: DSColor.splashCream
        case .soft: DSColor.splashSoft
        case .dark: DSColor.splashDark
        }
    }
}

/// A circle placed by its center, as an offset from the disc center.
struct SplashCircle: Equatable {
    let diameter: CGFloat
    let offset: CGSize
}

struct SplashDot: Equatable {
    let color: SplashDotColor
    let diameter: CGFloat
    let offset: CGSize
}

/// Splash geometry as offsets from the disc center, not absolute 390x844 coordinates, so the art keeps its
/// arrangement around the disc on any screen size.
struct SplashLayout: Equatable {
    let disc: CGFloat
    let checkSize: CGFloat
    let ring: SplashCircle
    let ringLineWidth: CGFloat
    let glow: SplashCircle
    let dots: [SplashDot]

    static let design = SplashLayout(
        disc: 168,
        checkSize: 112,
        ring: SplashCircle(diameter: 280, offset: CGSize(width: 0, height: -30)),
        ringLineWidth: 1.5,
        glow: SplashCircle(diameter: 620, offset: CGSize(width: -25, height: -259)),
        dots: [
            SplashDot(color: .cream, diameter: 18, offset: CGSize(width: 114, height: -145)),
            SplashDot(color: .soft, diameter: 12, offset: CGSize(width: -127, height: 107)),
            SplashDot(color: .dark, diameter: 10, offset: CGSize(width: 132, height: 91)),
        ]
    )
}
