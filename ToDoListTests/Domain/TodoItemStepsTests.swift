import Foundation
import Testing
@testable import MyApp

struct TodoItemStepsTests {
    private func step(_ text: String, done: Bool = false) -> Step {
        Step(title: try! StepTitle(text), isDone: done)
    }

    private func titles(_ item: TodoItem) -> [String] { item.steps.map(\.title.value) }

    @Test func startsWithoutSteps() {
        let item = makeTodoItem()
        #expect(item.steps.isEmpty)
        #expect(item.stepsProgress == nil)
    }

    // MARK: - add

    @Test func addStepAppendsAndReturnsTheNewID() throws {
        var item = makeTodoItem(steps: [step("A")])
        let id = try item.addStep(StepTitle("B"))
        #expect(titles(item) == ["A", "B"])
        #expect(item.steps.last?.id == id)
    }

    @Test func addStepThrowsAtTheLimitAndLeavesStepsUnchanged() throws {
        var item = makeTodoItem(steps: (1...TodoItem.maxSteps).map { step("Step \($0)") })
        #expect(throws: TodoItemError.tooManySteps) { try item.addStep(StepTitle("One more")) }
        #expect(item.steps.count == 20)
    }

    @Test func addStepIsAllowedUpToTheLimit() throws {
        var item = makeTodoItem(steps: (1..<TodoItem.maxSteps).map { step("Step \($0)") })
        try item.addStep(StepTitle("Last"))
        #expect(item.steps.count == 20)
    }

    @Test func initKeepsOnlyTheFirstMaxStepsSoTheLimitAlwaysHolds() {
        let item = makeTodoItem(steps: (1...25).map { step("Step \($0)") })
        #expect(item.steps.count == 20)
        #expect(item.steps.first?.title.value == "Step 1")
    }

    // MARK: - toggle, rename, remove

    @Test func toggleStepFlipsOnlyThatStep() throws {
        var item = makeTodoItem(steps: [step("A"), step("B")])
        try item.toggleStep(item.steps[1].id)
        #expect(item.steps.map(\.isDone) == [false, true])
    }

    @Test func renameStepChangesOnlyThatTitle() throws {
        var item = makeTodoItem(steps: [step("A"), step("B")])
        try item.renameStep(item.steps[0].id, to: StepTitle("Z"))
        #expect(titles(item) == ["Z", "B"])
    }

    @Test func removeStepKeepsTheRemainingOrder() throws {
        var item = makeTodoItem(steps: [step("A"), step("B"), step("C")])
        try item.removeStep(item.steps[1].id)
        #expect(titles(item) == ["A", "C"])
    }

    @Test func unknownStepIDThrowsStepNotFoundForEveryChange() throws {
        var item = makeTodoItem(steps: [step("A")])
        let unknown = StepID()
        #expect(throws: TodoItemError.stepNotFound) { try item.toggleStep(unknown) }
        #expect(throws: TodoItemError.stepNotFound) { try item.renameStep(unknown, to: StepTitle("Z")) }
        #expect(throws: TodoItemError.stepNotFound) { try item.removeStep(unknown) }
        #expect(titles(item) == ["A"])
    }

    // MARK: - move

    @Test(arguments: [(0, 2, ["B", "C", "A"]), (2, 0, ["C", "A", "B"]), (1, 1, ["A", "B", "C"]), (0, 1, ["B", "A", "C"])])
    func moveStepPutsTheStepAtTheTargetIndex(from: Int, to: Int, expected: [String]) throws {
        var item = makeTodoItem(steps: [step("A"), step("B"), step("C")])
        try item.moveStep(from: from, to: to)
        #expect(titles(item) == expected)
    }

    @Test(arguments: [(-1, 0), (3, 0), (0, -1), (0, 3)])
    func moveStepRejectsOutOfRangePositions(from: Int, to: Int) {
        var item = makeTodoItem(steps: [step("A"), step("B"), step("C")])
        #expect(throws: TodoItemError.invalidStepPosition) { try item.moveStep(from: from, to: to) }
        #expect(titles(item) == ["A", "B", "C"])
    }

    // MARK: - progress and independence

    @Test func progressCountsDoneSteps() {
        let item = makeTodoItem(steps: [step("A", done: true), step("B"), step("C", done: true)])
        #expect(item.stepsProgress == StepsProgress(done: 2, total: 3))
    }

    @Test func tickingEveryStepDoesNotCompleteTheTask() throws {
        var item = makeTodoItem(steps: [step("A")])
        try item.toggleStep(item.steps[0].id)
        #expect(!item.isCompleted)
    }

    @Test func completingTheTaskDoesNotTickSteps() {
        var item = makeTodoItem(steps: [step("A")])
        item.complete(at: .init(timeIntervalSince1970: 5_000))
        #expect(item.steps[0].isDone == false)
    }

    // MARK: - completing from steps

    private let doneAt = Date(timeIntervalSince1970: 5_000)

    @Test func completesWhenEveryStepIsDone() {
        var item = makeTodoItem(steps: [step("A", done: true), step("B", done: true)])
        item.completeIfAllStepsDone(at: doneAt)
        #expect(item.completedAt == doneAt)
    }

    @Test func staysOpenWhileAStepIsOpen() {
        var item = makeTodoItem(steps: [step("A", done: true), step("B")])
        item.completeIfAllStepsDone(at: doneAt)
        #expect(!item.isCompleted)
    }

    @Test func aTaskWithoutStepsIsNotCompleted() {
        var item = makeTodoItem()
        item.completeIfAllStepsDone(at: doneAt)
        #expect(!item.isCompleted)
    }

    @Test func keepsTheFirstCompletionTime() {
        let first = Date(timeIntervalSince1970: 1_000)
        var item = makeTodoItem(steps: [step("A", done: true)])
        item.complete(at: first)
        item.completeIfAllStepsDone(at: doneAt)
        #expect(item.completedAt == first)
    }

    @Test func untickingAStepDoesNotReopenTheTask() throws {
        var item = makeTodoItem(steps: [step("A", done: true)])
        item.completeIfAllStepsDone(at: doneAt)
        try item.toggleStep(item.steps[0].id)
        #expect(item.isCompleted)
    }
}
