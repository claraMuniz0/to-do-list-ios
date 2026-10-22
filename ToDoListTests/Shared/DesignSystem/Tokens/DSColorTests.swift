import SwiftUI
import Testing
@testable import MyApp

struct DSColorTests {
    @Test(arguments: [
        ("bg", DSColor.bg, "FFF8F0"),
        ("surface", DSColor.surface, "FFFFFF"),
        ("border", DSColor.border, "F0E2D4"),
        ("textPrimary", DSColor.textPrimary, "2B2118"),
        ("textSecondary", DSColor.textSecondary, "5E5044"),
        ("textMuted", DSColor.textMuted, "7D6E61"),
        ("accent", DSColor.accent, "C4401F"),
        ("accentSoft", DSColor.accentSoft, "FFE3DA"),
        ("onAccent", DSColor.onAccent, "FFFFFF"),
        ("danger", DSColor.danger, "B3261E"),
        ("doneChipBackground", DSColor.doneChipBackground, "EFE6DA"),
        ("toastBackground", DSColor.toastBackground, "2B2118"),
        ("toastAction", DSColor.toastAction, "FFB4A0"),
        ("welcomeGradientTop", DSColor.welcomeGradientTop, "FFE8D6"),
        ("illustrationGreen", DSColor.illustrationGreen, "7BC8A0"),
        ("illustrationPeach", DSColor.illustrationPeach, "FFC9B8"),
        ("illustrationBlue", DSColor.illustrationBlue, "B8C6FF"),
        ("shadowSoft", DSColor.shadowSoft, "EAD6C3"),
        ("shadowAccent", DSColor.shadowAccent, "8F2A10"),
        ("illustrationShadow", DSColor.illustrationShadow, "D94A2B26"),
        ("splashGradientTop", DSColor.splashGradientTop, "E0603A"),
        ("splashGradientBottom", DSColor.splashGradientBottom, "B03719"),
        ("splashGlow", DSColor.splashGlow, "FFFFFF33"),
        ("splashRing", DSColor.splashRing, "FFFFFF1F"),
        ("splashCream", DSColor.splashCream, "FFF8F0"),
        ("splashSoft", DSColor.splashSoft, "FFE3DA"),
        ("splashDark", DSColor.splashDark, "7A2610"),
        ("splashShadow", DSColor.splashShadow, "5A1A0A66"),
    ])
    func tokenMatchesDesign(name: String, color: Color, hex: String) {
        #expect(color.lightHex == hex, "\(name)")
    }
}
