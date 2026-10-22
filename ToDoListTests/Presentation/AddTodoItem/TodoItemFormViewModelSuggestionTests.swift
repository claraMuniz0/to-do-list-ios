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
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
        #expect(items.map(\.title) == ["A", "B", "C"])
        #expect(items.allSatisfy { $0.isSelected })
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
        guard case .suggestions = viewModel.suggestionState else { Issue.record("did not recover"); return }
    }

    @Test func selectionCountFollowsTogglesAndEdits() async {
        let (viewModel, _) = await makeSUT()
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
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
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
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

    @Test func suggestionsAreAvailableInAddModeOnceTheTitleIsFilled() {
        let spy = TodoItemRepositorySpy()
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8))
        let viewModel = TodoItemFormViewModel(
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getTodoItem: GetTodoItemUseCase(repository: spy),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
            suggestSteps: SuggestStepsUseCase(suggester: FakeStepSuggester())
        )
        #expect(!viewModel.canSuggestSteps)
        viewModel.title = "Plan trip"
        #expect(viewModel.canSuggestSteps)
        #expect(viewModel.suggestionPillTitle == "Break it down")
    }

    @Test func addingStopsAtTheStepLimit() async {
        let (viewModel, _) = await makeSUT(steps: (1...19).map { step("S\($0)") })
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
        #expect(items.count == 1)
        viewModel.addSelectedSuggestions()
        #expect(viewModel.steps.count == 20)
    }

    @Test func overlongEditedSuggestionIsSkippedWhenAdding() async {
        let (viewModel, _) = await makeSUT()
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
        viewModel.editSuggestion(items[0].id, to: String(repeating: "x", count: StepTitle.maxLength + 1))
        viewModel.addSelectedSuggestions()
        #expect(viewModel.steps.map(\.title.value) == ["B", "C"])
    }

    @Test func suggestionActionsAreIgnoredWithoutSuggestions() async {
        let (viewModel, _) = await makeSUT()
        viewModel.toggleSuggestion(UUID())
        viewModel.editSuggestion(UUID(), to: "x")
        viewModel.addSelectedSuggestions()
        #expect(viewModel.suggestionState == .idle)
        #expect(viewModel.steps.isEmpty)
        #expect(viewModel.selectedSuggestionCount == 0)
    }

    @Test func requestingWithoutClaudeDoesNothing() async {
        let (viewModel, suggester) = await makeSUT(withClaude: false)
        await viewModel.requestSuggestions()
        #expect(viewModel.suggestionState == .idle)
        #expect(suggester.calls.isEmpty)
    }

    @Test func aFailedRetryKeepsTheSuggestionsAndTheEditsAndReportsTheProblem() async {
        let (viewModel, suggester) = await makeSUT()
        await viewModel.requestSuggestions()
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
        viewModel.toggleSuggestion(items[0].id)
        suggester.outcome = .failure(.offline)
        await viewModel.requestSuggestions()
        #expect(viewModel.retryProblem == .failed(.offline))
        #expect(viewModel.selectedSuggestionCount == 2)
        guard case .suggestions(let kept) = viewModel.suggestionState else { Issue.record("lost suggestions"); return }
        #expect(kept.map(\.title) == ["A", "B", "C"])
        #expect(!viewModel.isSuggesting)
    }

    @Test func anEmptyRetryKeepsTheSuggestionsAndReportsEmpty() async {
        let (viewModel, suggester) = await makeSUT()
        await viewModel.requestSuggestions()
        suggester.outcome = .success([])
        await viewModel.requestSuggestions()
        #expect(viewModel.retryProblem == .empty)
        #expect(viewModel.selectedSuggestionCount == 3)
    }

    @Test func aSuccessfulRetryReplacesTheSuggestionsAndClearsTheProblem() async {
        let (viewModel, suggester) = await makeSUT()
        await viewModel.requestSuggestions()
        suggester.outcome = .failure(.failed)
        await viewModel.requestSuggestions()
        suggester.outcome = .success([try! StepTitle("Z")])
        await viewModel.requestSuggestions()
        #expect(viewModel.retryProblem == nil)
        guard case .suggestions(let items) = viewModel.suggestionState else { Issue.record("not suggestions"); return }
        #expect(items.map(\.title) == ["Z"])
    }

    @Test func dismissingClearsTheRetryProblem() async {
        let (viewModel, suggester) = await makeSUT()
        await viewModel.requestSuggestions()
        suggester.outcome = .failure(.failed)
        await viewModel.requestSuggestions()
        viewModel.dismissSuggestions()
        #expect(viewModel.retryProblem == nil)
        #expect(viewModel.suggestionState == .idle)
    }
}
