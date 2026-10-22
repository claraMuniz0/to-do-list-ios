import Testing
@testable import MyApp

struct StepTests {
    @Test func startsNotDone() throws {
        #expect(try Step(title: StepTitle("Pack")).isDone == false)
    }

    @Test func toggleFlipsDoneBothWays() throws {
        var step = try Step(title: StepTitle("Pack"))
        step.toggle()
        #expect(step.isDone)
        step.toggle()
        #expect(!step.isDone)
    }

    @Test func renameChangesOnlyTheTitle() throws {
        var step = try Step(title: StepTitle("Pack"), isDone: true)
        let id = step.id
        step.rename(try StepTitle("Pack the bag"))
        #expect(step.title.value == "Pack the bag")
        #expect(step.id == id)
        #expect(step.isDone)
    }
}
