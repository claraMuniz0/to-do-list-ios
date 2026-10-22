import Testing
@testable import MyApp

struct CircularIconButtonTests {
    @Test func targetIsAtLeastTheMinimumTouchTarget() {
        #expect(CircularIconButtonMetrics.diameter >= DSTouchTarget.minimum)
    }

    @Test func iconMatchesTheDesignSize() {
        #expect(CircularIconButtonMetrics.iconSize == 20)
    }
}
