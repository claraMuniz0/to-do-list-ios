import Testing
@testable import MyApp

struct StepsProgressTests {
    @Test func fractionIsDoneOverTotal() {
        #expect(StepsProgress(done: 2, total: 5).fraction == 0.4)
    }

    @Test func zeroDoneIsAFractionOfZero() {
        #expect(StepsProgress(done: 0, total: 3).fraction == 0)
    }

    @Test func allDoneIsAFractionOfOne() {
        #expect(StepsProgress(done: 3, total: 3).fraction == 1)
    }

    @Test func isCompleteOnlyWhenEveryStepIsDone() {
        #expect(StepsProgress(done: 3, total: 3).isComplete)
        #expect(!StepsProgress(done: 2, total: 3).isComplete)
    }

    @Test func labelReadsDoneOfTotal() {
        #expect(StepsProgress(done: 2, total: 5).label == "2 of 5")
    }
}
