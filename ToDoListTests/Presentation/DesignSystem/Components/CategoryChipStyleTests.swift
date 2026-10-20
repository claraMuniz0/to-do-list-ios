import Testing
@testable import MyApp

struct CategoryChipStyleTests {
    @Test func tagUsesCompactPaddingAndSmallFont() {
        #expect(CategoryChipStyle.tag.verticalPadding == 4)
        #expect(CategoryChipStyle.tag.horizontalPadding == 10)
        #expect(CategoryChipStyle.tag.font == .chipTag)
    }

    @Test func optionUsesLargerPaddingAndFont() {
        #expect(CategoryChipStyle.option.verticalPadding == 10)
        #expect(CategoryChipStyle.option.horizontalPadding == 16)
        #expect(CategoryChipStyle.option.font == .chipOption)
    }

    @Test func onlyOptionShowsSelectionStroke() {
        #expect(CategoryChipStyle.tag.selectionStrokeWidth == 0)
        #expect(CategoryChipStyle.option.selectionStrokeWidth == 2)
    }
}
