import Testing
@testable import MyApp

struct StepListTests {
    private func list(_ titles: String...) -> StepList {
        StepList(titles.map { Step(title: try! StepTitle($0)) })
    }

    private func titles(_ list: StepList) -> [String] { list.steps.map(\.title.value) }

    @Test func addAppendsAndReturnsTheNewID() throws {
        var steps = list("A")
        let id = try steps.add(StepTitle("B"))
        #expect(titles(steps) == ["A", "B"])
        #expect(steps.steps.last?.id == id)
    }

    @Test func addThrowsAtTheLimit() throws {
        var steps = StepList((1...StepList.maxSteps).map { Step(title: try! StepTitle("Step \($0)")) })
        #expect(throws: TodoItemError.tooManySteps) { try steps.add(StepTitle("One more")) }
        #expect(steps.steps.count == 20)
    }

    @Test func initKeepsOnlyTheFirstMaxSteps() {
        let steps = StepList((1...25).map { Step(title: try! StepTitle("Step \($0)")) })
        #expect(steps.steps.count == 20)
        #expect(steps.steps.first?.title.value == "Step 1")
    }

    @Test func toggleRenameRemoveTargetOnlyThatStep() throws {
        var steps = list("A", "B", "C")
        try steps.toggle(steps.steps[1].id)
        try steps.rename(steps.steps[0].id, to: StepTitle("Z"))
        try steps.remove(steps.steps[2].id)
        #expect(titles(steps) == ["Z", "B"])
        #expect(steps.steps.map(\.isDone) == [false, true])
    }

    @Test func unknownIDThrowsStepNotFound() {
        var steps = list("A")
        let unknown = StepID()
        #expect(throws: TodoItemError.stepNotFound) { try steps.toggle(unknown) }
        #expect(throws: TodoItemError.stepNotFound) { try steps.rename(unknown, to: StepTitle("Z")) }
        #expect(throws: TodoItemError.stepNotFound) { try steps.remove(unknown) }
    }

    @Test(arguments: [(0, 2, ["B", "C", "A"]), (2, 0, ["C", "A", "B"]), (1, 1, ["A", "B", "C"])])
    func moveBringsTheStepToTheTargetIndex(from: Int, to: Int, expected: [String]) throws {
        var steps = list("A", "B", "C")
        try steps.move(from: from, to: to)
        #expect(titles(steps) == expected)
    }

    @Test(arguments: [(-1, 0), (3, 0), (0, -1), (0, 3)])
    func moveRejectsOutOfRangeIndexes(from: Int, to: Int) {
        var steps = list("A", "B", "C")
        #expect(throws: TodoItemError.invalidStepPosition) { try steps.move(from: from, to: to) }
        #expect(titles(steps) == ["A", "B", "C"])
    }

    @Test func progressIsNilWithoutStepsAndCountsDoneOtherwise() throws {
        #expect(StepList().progress == nil)
        var steps = list("A", "B")
        try steps.toggle(steps.steps[0].id)
        #expect(steps.progress == StepsProgress(done: 1, total: 2))
    }
}
