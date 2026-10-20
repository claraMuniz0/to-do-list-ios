import SwiftUI
import Testing
@testable import MyApp

struct CategoryChipColorsTests {
    @Test func usesPaletteWhenNoOverrides() {
        let colors = CategoryChipColors(palette: .green, backgroundOverride: nil, foregroundOverride: nil)
        #expect(colors.background.lightHex == "DDF3E4")
        #expect(colors.foreground.lightHex == "27704A")
    }

    @Test func overridesTakePrecedenceOverPalette() {
        let colors = CategoryChipColors(palette: .blue, backgroundOverride: DSColor.doneChipBackground, foregroundOverride: DSColor.textSecondary)
        #expect(colors.background.lightHex == "EFE6DA")
        #expect(colors.foreground.lightHex == "5E5044")
    }

    @Test func selectedOptionStrokeIsAccentOthersClear() {
        #expect(CategoryChipColors.stroke(isSelected: true).lightHex == "C4401F")
        #expect(CategoryChipColors.stroke(isSelected: false).lightHex == "00000000")
    }

    @Test func tagReservesNoStrokeWidth() {
        #expect(CategoryChipStyle.tag.selectionStrokeWidth == 0)
        #expect(CategoryChipStyle.option.selectionStrokeWidth == 2)
    }
}
