import SwiftUI
import Testing
@testable import MyApp

struct StepsProgressBarStyleTests {
    @Test func zeroDoneIsAnEmptyTrack() {
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 0, total: 5)).fillFraction == 0)
    }

    @Test func partialProgressMatchesTheDesign() {
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 2, total: 5)).fillFraction == 0.4)
        // 140 / 350 in the design.
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 2, total: 5)).fillWidth(in: 350) == 140)
    }

    @Test func allDoneIsAFullTrack() {
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 5, total: 5)).fillFraction == 1)
    }

    @Test func fractionIsClampedIntoTheTrack() {
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 7, total: 5)).fillFraction == 1)
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: -1, total: 5)).fillFraction == 0)
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 0, total: 0)).fillFraction == 0)
    }

    @Test func colorsAndMetricsFollowTheDesign() {
        #expect(StepsProgressBarStyle.trackColor.lightHex == DSColor.border.lightHex)
        #expect(StepsProgressBarStyle.fillColor.lightHex == DSColor.accent.lightHex)
        #expect(StepsProgressBarStyle.height == 6)
        #expect(StepsProgressBarStyle.cornerRadius == 3)
    }

    @Test func accessibilityLabelSpeaksTheCount() {
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 2, total: 5)).accessibilityLabel == "2 of 5 steps done")
        #expect(StepsProgressBarStyle(progress: StepsProgress(done: 1, total: 1)).accessibilityLabel == "1 of 1 steps done")
    }
}
