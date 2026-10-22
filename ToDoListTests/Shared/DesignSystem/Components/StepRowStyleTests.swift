import SwiftUI
import Testing
@testable import MyApp

struct StepRowStyleTests {
    @Test func openStepUsesPrimaryTextAndSurfaceCheckbox() {
        let style = StepRowStyle(isDone: false)
        #expect(style.textColor.lightHex == DSColor.textPrimary.lightHex)
        #expect(style.checkboxFill.lightHex == DSColor.surface.lightHex)
        #expect(style.checkboxStroke.lightHex == DSColor.border.lightHex)
        #expect(style.showsCheckmark == false)
    }

    @Test func doneStepIsMutedAndAccentChecked() {
        let style = StepRowStyle(isDone: true)
        #expect(style.textColor.lightHex == DSColor.textMuted.lightHex)
        #expect(style.checkboxFill.lightHex == DSColor.accent.lightHex)
        #expect(style.checkboxStroke.lightHex == DSColor.accent.lightHex)
        #expect(style.showsCheckmark)
    }

    @Test func doneStepIsNotStruckThrough() {
        #expect(StepRowStyle(isDone: true).strikesThroughText == false)
        #expect(StepRowStyle(isDone: false).strikesThroughText == false)
    }

    @Test func valueAndActionNameFollowState() {
        #expect(StepRowStyle(isDone: false).accessibilityValue == "Not done")
        #expect(StepRowStyle(isDone: true).accessibilityValue == "Done")
        #expect(StepRowStyle(isDone: false).toggleActionName == "Mark as done")
        #expect(StepRowStyle(isDone: true).toggleActionName == "Mark as not done")
    }

    @Test func reorderActionNamesAreFixed() {
        #expect(StepRowStyle.moveUpActionName == "Move up")
        #expect(StepRowStyle.moveDownActionName == "Move down")
    }

    @Test func hitAreasAreAtLeast44Points() {
        #expect(StepRowStyle.hitArea >= 44)
        #expect(StepRowStyle.hitArea == DSTouchTarget.minimum)
    }

    @Test func rowHeightIsTheDesign52() {
        #expect(StepRowStyle.minRowHeight == 52)
    }

    @Test func deleteActionIsNamedForVoiceOver() {
        #expect(StepRowStyle.deleteActionName == "Delete step")
    }

    @Test func emptyTextStillGivesTheCheckboxAName() {
        #expect(StepRowStyle.checkboxLabel(for: "") == "Step")
        #expect(StepRowStyle.checkboxLabel(for: "  ") == "Step")
        #expect(StepRowStyle.checkboxLabel(for: "Pack") == "Pack")
    }
}
