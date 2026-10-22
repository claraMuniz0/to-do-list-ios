import SwiftUI
import Testing
@testable import MyApp

struct SuggestPillStyleTests {
    @Test func idlePillIsEnabledAndShowsTheSparkle() {
        let style = SuggestPillStyle(isLoading: false)
        #expect(style.isDisabled == false)
        #expect(style.showsSpinner == false)
        #expect(style.iconName == "sparkles")
    }

    @Test func loadingPillIsDisabledAndShowsASpinner() {
        let style = SuggestPillStyle(isLoading: true)
        #expect(style.isDisabled)
        #expect(style.showsSpinner)
    }

    @Test func colorsFollowTheDesign() {
        #expect(SuggestPillStyle.fill.lightHex == DSColor.accentSoft.lightHex)
        #expect(SuggestPillStyle.stroke.lightHex == DSColor.accent.lightHex)
        #expect(SuggestPillStyle.foreground.lightHex == DSColor.accent.lightHex)
    }

    @Test func hitAreaIsAtLeast44Points() {
        #expect(SuggestPillStyle.minHitHeight >= 44)
    }

    @Test func loadingIsAnnouncedAndIdleHasNoValue() {
        #expect(SuggestPillStyle(isLoading: true).accessibilityValue == "Thinking of steps")
        #expect(SuggestPillStyle(isLoading: false).accessibilityValue == nil)
    }

    @Test func pillFontIsOutfit13Semibold() {
        #expect(DSFont.suggestPill.spec.family == "Outfit")
        #expect(DSFont.suggestPill.spec.size == 13)
        #expect(DSFont.suggestPill.spec.weight == .semibold)
    }
}
