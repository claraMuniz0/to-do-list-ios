import Testing
@testable import MyApp

struct ChipPaletteTests {
    @Test func seededCategoriesMapToBlueBrickGreen() {
        #expect(ChipPalette(colorKey: Category.work.color.key) == .blue)
        #expect(ChipPalette(colorKey: Category.personal.color.key) == .brick)
        #expect(ChipPalette(colorKey: Category.shopping.color.key) == .green)
    }

    @Test func paletteNamesMapToThemselves() {
        #expect(ChipPalette(colorKey: "blue") == .blue)
        #expect(ChipPalette(colorKey: "brick") == .brick)
        #expect(ChipPalette(colorKey: "green") == .green)
    }

    @Test func unknownOrEmptyKeyFallsBackToBrick() {
        #expect(ChipPalette(colorKey: "") == .brick)
        #expect(ChipPalette(colorKey: "unknown") == .brick)
    }

    @Test func keyMatchingIgnoresCase() {
        #expect(ChipPalette(colorKey: "Work") == .blue)
    }

    @Test func blueColorsMatchDesign() {
        #expect(ChipPalette.blue.background.lightHex == "E4EAFF")
        #expect(ChipPalette.blue.foreground.lightHex == "3449A8")
    }

    @Test func brickColorsMatchDesign() {
        #expect(ChipPalette.brick.background.lightHex == "FFE3DA")
        #expect(ChipPalette.brick.foreground.lightHex == "A83A1F")
    }

    @Test func greenColorsMatchDesign() {
        #expect(ChipPalette.green.background.lightHex == "DDF3E4")
        #expect(ChipPalette.green.foreground.lightHex == "27704A")
    }
}
