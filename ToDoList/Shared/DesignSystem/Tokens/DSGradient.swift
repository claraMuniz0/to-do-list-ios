import SwiftUI

/// Gradient tokens, kept as plain stops so they can be tested; `linearGradient` builds the SwiftUI value.
struct DSGradient: Equatable {
    struct Stop: Equatable {
        let color: Color
        let location: CGFloat
    }

    let stops: [Stop]

    /// Top to bottom. Fully faded into `bg` by 38% of the height, so the rest of the screen is flat.
    static let welcome = DSGradient(stops: [
        Stop(color: DSColor.welcomeGradientTop, location: 0),
        Stop(color: DSColor.bg, location: 0.38),
    ])

    /// Top to bottom, coral into deep brick; the splash screen's whole background.
    static let splash = DSGradient(stops: [
        Stop(color: DSColor.splashGradientTop, location: 0),
        Stop(color: DSColor.splashGradientBottom, location: 1),
    ])

    var linearGradient: LinearGradient {
        LinearGradient(
            stops: stops.map { Gradient.Stop(color: $0.color, location: $0.location) },
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
