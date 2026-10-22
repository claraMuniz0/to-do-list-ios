import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoItemFormViewModelStepsTests {
    private let calendar = Calendar.utcGregorian

    private func makeSUT(for item: TodoItem) -> (viewModel: TodoItemFormViewModel, spy: TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        spy.storedItems = [item]
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8))
        let viewModel = TodoItemFormViewModel(
            mode: .edit(item.id),
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getTodoItem: GetTodoItemUseCase(repository: spy),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        return (viewModel, spy)
    }

    private func step(_ text: String, done: Bool = false) -> Step {
        Step(title: try! StepTitle(text), isDone: done)
    }

    private func titles(_ viewModel: TodoItemFormViewModel) -> [String] { viewModel.steps.map(\.title.value) }

    @Test func startsWithNoStepsAndNoProgress() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        #expect(viewModel.steps.isEmpty)
        #expect(viewModel.stepsProgress == nil)
        #expect(viewModel.canAddStep)
    }

    @Test func loadingAnItemFillsItsSteps() async {
        let (viewModel, _) = makeSUT(for: makeTodoItem(steps: [step("A"), step("B", done: true)]))
        await viewModel.load()
        #expect(titles(viewModel) == ["A", "B"])
        #expect(viewModel.stepsProgress == StepsProgress(done: 1, total: 2))
    }

    @Test func addStepTrimsAndAppends() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        #expect(viewModel.addStep("  Pack the bag \n"))
        #expect(viewModel.addStep("Book a taxi"))
        #expect(titles(viewModel) == ["Pack the bag", "Book a taxi"])
    }

    @Test(arguments: ["", "   ", "\n"])
    func addStepRejectsBlankText(text: String) {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        #expect(!viewModel.addStep(text))
        #expect(viewModel.steps.isEmpty)
    }

    @Test func addStepRejectsTextOverTheMaximumLength() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        #expect(!viewModel.addStep(String(repeating: "a", count: StepTitle.maxLength + 1)))
        #expect(viewModel.steps.isEmpty)
    }

    @Test func addStopsAtTheLimit() {
        let (viewModel, _) = makeSUT(for: makeTodoItem(steps: (1...20).map { step("Step \($0)") }))
        viewModel.setSteps(StepList((1...20).map { step("Step \($0)") }))
        #expect(!viewModel.canAddStep)
        #expect(!viewModel.addStep("One more"))
        #expect(viewModel.steps.count == 20)
    }

    @Test func toggleRenameRemoveAndMoveChangeTheDraft() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        for text in ["A", "B", "C"] { viewModel.addStep(text) }
        let ids = viewModel.steps.map(\.id)

        viewModel.toggleStep(ids[0])
        #expect(viewModel.renameStep(ids[1], to: "  Bee "))
        viewModel.removeStep(ids[2])
        viewModel.moveStep(from: 1, to: 0)

        #expect(titles(viewModel) == ["Bee", "A"])
        #expect(viewModel.steps.map(\.isDone) == [false, true])
    }

    @Test func renameRejectsBlankTextAndKeepsTheOldTitle() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        viewModel.addStep("A")
        #expect(!viewModel.renameStep(viewModel.steps[0].id, to: "  "))
        #expect(titles(viewModel) == ["A"])
    }

    @Test func changesToUnknownStepsOrPositionsAreIgnored() {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        viewModel.addStep("A")
        viewModel.toggleStep(StepID())
        viewModel.removeStep(StepID())
        viewModel.moveStep(from: 5, to: 0)
        #expect(!viewModel.renameStep(StepID(), to: "Z"))
        #expect(titles(viewModel) == ["A"])
        #expect(viewModel.steps.map(\.isDone) == [false])
    }

    @Test func stepChangesDoNotAffectCanSave() async {
        let (viewModel, _) = makeSUT(for: makeTodoItem())
        await viewModel.load()
        let before = viewModel.canSave
        viewModel.addStep("A")
        #expect(viewModel.canSave == before)
    }

    @Test func savingPersistsTheEditedSteps() async {
        let item = makeTodoItem(steps: [step("A"), step("B")])
        let (viewModel, spy) = makeSUT(for: item)
        await viewModel.load()

        viewModel.toggleStep(viewModel.steps[0].id)
        viewModel.removeStep(viewModel.steps[1].id)
        viewModel.addStep("C")
        #expect(await viewModel.save())

        #expect(spy.storedItems.first?.steps.map(\.title.value) == ["A", "C"])
        #expect(spy.storedItems.first?.steps.map(\.isDone) == [true, false])
    }

    @Test func savingWithoutTouchingStepsKeepsThem() async {
        let item = makeTodoItem(steps: [step("A")])
        let (viewModel, spy) = makeSUT(for: item)
        await viewModel.load()
        #expect(await viewModel.save())
        #expect(spy.storedItems.first?.steps == item.steps)
    }
}
