import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoItemFormViewModelSuggestionTests {
    private let calendar = Calendar.utcGregorian

    private func makeSUT(
        steps: [Step] = [], suggested: [String] = ["A", "B", "C"], withClaude: Bool = true
    ) async -> (viewModel: TodoItemFormViewModel, suggester: FakeStepSuggester) {
        let item = makeTodoItem(steps: steps)
        let spy = TodoItemRepositorySpy()
        spy.storedItems = [item]
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8))
        let suggester = FakeStepSuggester(titles: suggested)
        let viewModel = TodoItemFormViewModel(
            mode: .edit(item.id),
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getTodoItem: GetTodoItemUseCase(repository: spy),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
            suggestSteps: withClaude ? SuggestStepsUseCase(suggester: suggester) : nil
        )
        await viewModel.load()
        return (viewModel, suggester)
    }

    private func step(_ text: String) -> Step { Step(title: try! StepTitle(text)) }

    @Test func entryPointIsHiddenWithoutClaude() async {
        let (viewModel, _) = await makeSUT(withClaude: false)
        #expect(!viewModel.canSuggestSteps)
    }

    @Test func entryPointIsHiddenWhenTheListIsFullOrTheTitleIsBlank() async {
        let (full, _) = await makeSUT(steps: (1...20).map { step("S\($0)") })
        #expect(!full.canSuggestSteps)
        let (blank, _) = await makeSUT()
        blank.title = "  "
        #expect(!blank.canSuggestSteps)
    }

    @Test func pillSaysBreakItDownUntilTheTaskHasSteps() async {
        let (empty, _) = await makeSUT()
        #expect(empty.suggestionPillTitle == "Break it down")
        let (some, _) = await makeSUT(steps: [step("X")])
        #expect(some.suggestionPillTitle == "Suggest more")
    }

    @Test func requestingFillsPreselectedSuggestionsAndSendsTheTask() async {
        let (viewModel, suggester) = await makeSUT(steps: [step("X")])
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { return Issue.record("not suggestions") }
        #expect(items.map(\.title) == ["A", "B", "C"])
        #expect(items.allSatisfy(\.isSelected))
        #expect(suggester.calls.first?.existingSteps == ["X"])
    }

    @Test func emptyResultIsReportedAsEmpty() async {
        let (viewModel, _) = await makeSUT(suggested: [])
        await viewModel.requestSuggestions()
        #expect(viewModel.suggestionState == .empty)
    }

    @Test func failureKeepsTheErrorForTryAgain() async {
        let (viewModel, suggester) = await makeSUT()
        suggester.outcome = .failure(.offline)
        await viewModel.requestSuggestions()
        #expect(viewModel.suggestionState == .failed(.offline))
        suggester.outcome = .success([try! StepTitle("Z")])
        await viewModel.requestSuggestions()
        guard case .suggestions = viewModel.suggestionState else { return Issue.record("did not recover") }
    }

    @Test func selectionCountFollowsTogglesAndEdits() async {
        let (viewModel, _) = await makeSUT()
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { return Issue.record("not suggestions") }
        #expect(viewModel.selectedSuggestionCount == 3)
        viewModel.toggleSuggestion(items[0].id)
        #expect(viewModel.selectedSuggestionCount == 2)
        viewModel.editSuggestion(items[1].id, to: "  Renamed ")
        viewModel.addSelectedSuggestions()
        #expect(viewModel.steps.map(\.title.value) == ["Renamed", "C"])
    }

    @Test func blankEditedSuggestionsAreSkippedWhenAdding() async {
        let (viewModel, _) = await makeSUT()
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { return Issue.record("not suggestions") }
        viewModel.editSuggestion(items[0].id, to: "   ")
        viewModel.addSelectedSuggestions()
        #expect(viewModel.steps.map(\.title.value) == ["B", "C"])
    }

    @Test func addingClosesTheSheetAndKeepsExistingSteps() async {
        let (viewModel, _) = await makeSUT(steps: [step("X")])
        await viewModel.requestSuggestions()
        viewModel.addSelectedSuggestions()
        #expect(viewModel.suggestionState == .idle)
        #expect(viewModel.steps.map(\.title.value) == ["X", "A", "B", "C"])
    }

    @Test func dismissingDiscardsTheSuggestions() async {
        let (viewModel, _) = await makeSUT()
        await viewModel.requestSuggestions()
        viewModel.dismissSuggestions()
        #expect(viewModel.suggestionState == .idle)
        #expect(viewModel.steps.isEmpty)
    }
}
