import SwiftUI

/// Typed access to the asset-catalog color sets. Names mirror the `.pen` variables.
/// Light appearance only for the MVP, so the sets carry no dark variants.
enum DSColor {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let border = Color("border")
    /// Stronger edge for form controls: `border` is ~1.2:1 on the surface, too faint to mark a field (WCAG 1.4.11).
    static let borderControl = Color("border-control")
    static let textPrimary = Color("text-primary")
    static let textSecondary = Color("text-secondary")
    static let textMuted = Color("text-muted")
    static let accent = Color("accent")
    static let accentSoft = Color("accent-soft")
    static let onAccent = Color("on-accent")
    static let danger = Color("danger")

    /// Neutral chip fill for a done `TaskRow`, replacing the category palette so done rows read as muted.
    static let doneChipBackground = Color("done-chip-bg")
    static let toastBackground = Color("toast-bg")
    static let toastAction = Color("toast-action")
    static let welcomeGradientTop = Color("welcome-gradient-top")

    static let illustrationGreen = Color("illustration-green")
    static let illustrationPeach = Color("illustration-peach")
    static let illustrationBlue = Color("illustration-blue")
    /// Shadow tint for the illustration disc; kept separate from `shadowSoft` because it is blurred, not hard-edged.
    static let illustrationShadow = Color("illustration-shadow")

    static let splashGradientTop = Color("splash-gradient-top")
    static let splashGradientBottom = Color("splash-gradient-bottom")
    static let splashGlow = Color("splash-glow")
    static let splashRing = Color("splash-ring")
    static let splashCream = Color("splash-cream")
    static let splashSoft = Color("splash-soft")
    static let splashDark = Color("splash-dark")
    /// Shadow tint for the splash disc; darker and more opaque than `illustrationShadow` because it sits on saturated coral.
    static let splashShadow = Color("splash-shadow")

    static let shadowSoft = Color("shadow-soft")
    static let shadowAccent = Color("shadow-accent")
    static let toastShadow = Color("toast-shadow")
}
