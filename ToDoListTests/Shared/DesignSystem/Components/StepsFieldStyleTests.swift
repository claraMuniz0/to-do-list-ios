import SwiftUI
import Testing
@testable import MyApp

struct StepsFieldStyleTests {
    private func style(
        count: Int, progress: StepsProgress? = nil, showsProgress: Bool = true, canAdd: Bool = true
    ) -> StepsFieldStyle {
        StepsFieldStyle(stepCount: count, progress: progress, showsProgress: showsProgress, canAdd: canAdd)
    }

    @Test func progressVariantShowsCountTextAndBar() {
        let sut = style(count: 5, progress: StepsProgress(done: 2, total: 5))
        #expect(sut.headerDetail == "2 of 5")
        #expect(sut.showsProgressBar)
    }

    @Test func tagVariantShowsStepCountAndNoBar() {
        let sut = style(count: 3, progress: StepsProgress(done: 1, total: 3), showsProgress: false)
        #expect(sut.headerDetail == "3 steps")
        #expect(sut.showsProgressBar == false)
    }

    @Test func tagUsesSingularForOneStep() {
        #expect(style(count: 1, showsProgress: false).headerDetail == "1 step")
    }

    @Test func noStepsHidesBarAndDetail() {
        let sut = style(count: 0, progress: nil)
        #expect(sut.headerDetail == nil)
        #expect(sut.showsProgressBar == false)
    }

    @Test func addRowFollowsCanAdd() {
        #expect(style(count: 2, canAdd: true).showsAddRow)
        #expect(style(count: 20, canAdd: false).showsAddRow == false)
    }

    @Test func onlyTheLastRowHasNoDivider() {
        let sut = style(count: 3, canAdd: false)
        #expect(sut.showsDivider(at: 0))
        #expect(sut.showsDivider(at: 1))
        #expect(sut.showsDivider(at: 2) == false)
    }

    @Test func dividerStaysWhenAnAddRowFollows() {
        #expect(style(count: 3, canAdd: true).showsDivider(at: 2))
    }

    @Test func moveActionsExistOnlyInsideTheList() {
        let sut = style(count: 3)
        #expect(sut.canMoveUp(at: 0) == false)
        #expect(sut.canMoveUp(at: 1))
        #expect(sut.canMoveDown(at: 1))
        #expect(sut.canMoveDown(at: 2) == false)
    }

    @Test func copyMatchesTheSpec() {
        #expect(StepsFieldStyle.title == "Steps")
        #expect(StepsFieldStyle.addPlaceholder == "Add a step")
    }
}
