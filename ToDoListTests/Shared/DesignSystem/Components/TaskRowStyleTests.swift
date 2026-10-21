import SwiftUI
import Testing
@testable import MyApp

struct TaskRowStyleTests {
    @Test func openRowUsesPrimaryTitleAndRaisedSurface() {
        let style = TaskRowStyle(isDone: false)
        #expect(style.titleColor.lightHex == DSColor.textPrimary.lightHex)
        #expect(style.surfaceFill.lightHex == DSColor.surface.lightHex)
        #expect(style.shadow == .soft)
        #expect(style.showsCheckmark == false)
    }

    @Test func doneRowIsMutedFlatAndChecked() {
        let style = TaskRowStyle(isDone: true)
        #expect(style.titleColor.lightHex == DSColor.textSecondary.lightHex)
        #expect(style.surfaceFill.lightHex == DSColor.bg.lightHex)
        #expect(style.shadow == .none)
        #expect(style.showsCheckmark)
    }

    @Test func designDoesNotStrikeThroughDoneTitle() {
        #expect(TaskRowStyle(isDone: true).strikesThroughTitle == false)
        #expect(TaskRowStyle(isDone: false).strikesThroughTitle == false)
    }

    @Test(arguments: ChipPalette.allCases)
    func openChipKeepsPaletteColors(palette: ChipPalette) {
        let style = TaskRowStyle(isDone: false)
        #expect(style.chipBackground(for: palette).lightHex == palette.background.lightHex)
        #expect(style.chipForeground(for: palette).lightHex == palette.foreground.lightHex)
    }

    @Test(arguments: ChipPalette.allCases)
    func doneChipIsNeutralRegardlessOfPalette(palette: ChipPalette) {
        let style = TaskRowStyle(isDone: true)
        #expect(style.chipBackground(for: palette).lightHex == DSColor.doneChipBackground.lightHex)
        #expect(style.chipForeground(for: palette).lightHex == DSColor.textSecondary.lightHex)
    }

    @Test func openRowLabelIncludesTitleDescriptionAndCategory() {
        let style = TaskRowStyle(isDone: false)
        #expect(style.accessibilityLabel(title: "Prepare slides", description: "Quarterly deck", categoryName: "Work")
            == "Prepare slides, Quarterly deck, Work")
    }

    @Test func rowLabelSkipsMissingOrEmptyDescription() {
        let style = TaskRowStyle(isDone: false)
        #expect(style.accessibilityLabel(title: "Buy milk", description: nil, categoryName: "Shopping") == "Buy milk, Shopping")
        #expect(style.accessibilityLabel(title: "Buy milk", description: "", categoryName: "Shopping") == "Buy milk, Shopping")
    }

    @Test func doneRowLabelOmitsHiddenDescription() {
        let style = TaskRowStyle(isDone: true)
        #expect(style.accessibilityLabel(title: "Prepare slides", description: "Quarterly deck", categoryName: "Work")
            == "Prepare slides, Work")
    }

    @Test func valueAndActionNameFollowState() {
        #expect(TaskRowStyle(isDone: false).accessibilityValue == "Not completed")
        #expect(TaskRowStyle(isDone: true).accessibilityValue == "Completed")
        #expect(TaskRowStyle(isDone: false).toggleActionName == "Mark as completed")
        #expect(TaskRowStyle(isDone: true).toggleActionName == "Mark as not completed")
    }

    @Test func rowHintSaysTheDefaultActionOpensTheTask() {
        #expect(TaskRowStyle(isDone: false).openHint == "Opens the task for editing")
        #expect(TaskRowStyle(isDone: true).openHint == "Opens the task for editing")
    }
}
