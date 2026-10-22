import SwiftUI
import Testing
@testable import MyApp

struct DSFontTests {
    @Test func screenTitleIsFraunces36SemiboldItalic() {
        let spec = DSFont.screenTitle.spec
        #expect(spec.family == "Fraunces")
        #expect(spec.size == 36)
        #expect(spec.weight == .semibold)
        #expect(spec.isItalic)
    }

    @Test func emptyTitleIsFraunces26Bold() {
        let spec = DSFont.emptyTitle.spec
        #expect(spec.family == "Fraunces")
        #expect(spec.size == 26)
        #expect(spec.weight == .bold)
        #expect(!spec.isItalic)
    }

    @Test func greetingIsCaveat24Semibold() {
        let spec = DSFont.greeting.spec
        #expect(spec.family == "Caveat")
        #expect(spec.size == 24)
        #expect(spec.weight == .semibold)
    }

    @Test func taglineIsCaveat24Regular() {
        let spec = DSFont.tagline.spec
        #expect(spec.family == "Caveat")
        #expect(spec.size == 24)
        #expect(spec.weight == .regular)
        #expect(!spec.isItalic)
    }

    @Test func rowTitleAndDescriptionUseBricolage() {
        #expect(DSFont.rowTitle.spec.family == "Bricolage Grotesque")
        #expect(DSFont.rowTitle.spec.size == 16)
        #expect(DSFont.rowTitle.spec.weight == .semibold)
        #expect(DSFont.rowDescription.spec.size == 14)
        #expect(DSFont.rowDescription.spec.weight == .regular)
        #expect(DSFont.inputText.spec.size == 16)
    }

    @Test func uiFontsUseOutfitSemibold() {
        let sizes: [(DSFont, CGFloat)] = [
            (.chipTag, 12), (.chipOption, 14), (.pill, 14), (.button, 17), (.toast, 15), (.stepCount, 12),
        ]
        for (font, size) in sizes {
            #expect(font.spec.family == "Outfit")
            #expect(font.spec.size == size)
            #expect(font.spec.weight == .semibold)
        }
    }

    @Test func everyTokenScalesWithDynamicType() {
        for font in DSFont.allCases {
            #expect(font.spec.textStyle != nil)
        }
    }

    @Test func allFamiliesAreOneOfTheBundledFive() {
        let bundled: Set<String> = ["Fraunces", "Bricolage Grotesque", "Outfit", "Caveat", "DM Mono"]
        for font in DSFont.allCases {
            #expect(bundled.contains(font.spec.family))
        }
    }
}
