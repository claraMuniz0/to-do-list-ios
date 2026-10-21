import Testing
@testable import MyApp

struct UndoToastPolicyTests {
    @Test func dismissesAfterFiveSecondsWithoutAssistiveTechnology() {
        #expect(UndoToastPolicy.autoDismissDelay(assistiveTechnologyIsOn: false) == .seconds(5))
    }

    @Test func staysUntilDismissedWithAssistiveTechnology() {
        #expect(UndoToastPolicy.autoDismissDelay(assistiveTechnologyIsOn: true) == nil)
    }

    @Test func announcementWaitsForTheCoverToFinishDismissing() {
        #expect(UndoToastPolicy.announcementDelay > .zero)
    }

    @Test func reduceMotionDropsTheSlide() {
        #expect(UndoToastPolicy.slides(reduceMotion: true) == false)
        #expect(UndoToastPolicy.slides(reduceMotion: false))
    }
}
