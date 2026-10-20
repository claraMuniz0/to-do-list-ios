import UIKit
import Testing
@testable import MyApp

struct DSFontOpticalSizeTests {
    @Test func opticalSizeFollowsPointSizeWithinTheAxisRange() {
        #expect(DSFont.opticalSize(forPointSize: 16) == 16)
        #expect(DSFont.opticalSize(forPointSize: 8) == 12)
        #expect(DSFont.opticalSize(forPointSize: 200) == 96)
    }

    @Test func onlyBricolageTokensUseOpticalSize() {
        let tokens = DSFont.allCases.filter(\.usesOpticalSize)
        #expect(Set(tokens) == [.rowTitle, .rowDescription, .inputText])
    }

    @Test func weightMapsToTheWghtAxis() {
        #expect(DSFont.rowTitle.variationWeight == 600)
        #expect(DSFont.inputText.variationWeight == 400)
    }

    @Test func uiFontIsBricolageAtTheScaledSize() {
        let font = DSFont.inputText.uiFont(for: .large)
        #expect(font.familyName == "Bricolage Grotesque")
        #expect(font.pointSize == 16)
    }

    @Test func uiFontGrowsWithTheContentSizeCategory() {
        let large = DSFont.inputText.uiFont(for: .large).pointSize
        let accessibility = DSFont.inputText.uiFont(for: .accessibilityExtraLarge).pointSize
        #expect(accessibility > large)
    }
}
