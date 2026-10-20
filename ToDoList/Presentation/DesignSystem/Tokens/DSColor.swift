import SwiftUI

/// Typed access to the asset-catalog color sets. Names mirror the `.pen` variables.
/// Light appearance only for the MVP, so the sets carry no dark variants.
enum DSColor {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let border = Color("border")
    static let textPrimary = Color("text-primary")
    static let textSecondary = Color("text-secondary")
    static let textMuted = Color("text-muted")
    static let accent = Color("accent")
    static let accentSoft = Color("accent-soft")
    static let onAccent = Color("on-accent")
    static let danger = Color("danger")

    static let doneChipBackground = Color("done-chip-bg")
    static let toastBackground = Color("toast-bg")
    static let toastAction = Color("toast-action")
    static let welcomeGradientTop = Color("welcome-gradient-top")

    static let illustrationGreen = Color("illustration-green")
    static let illustrationPeach = Color("illustration-peach")
    static let illustrationBlue = Color("illustration-blue")
    static let illustrationShadow = Color("illustration-shadow")

    static let shadowSoft = Color("shadow-soft")
    static let shadowAccent = Color("shadow-accent")
}
