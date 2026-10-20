import Foundation
import Testing
@testable import MyApp

@MainActor
struct AddTodoItemViewModelTests {
    private let calendar = Calendar.utcGregorian
    private var now: Date { calendar.makeDate(2026, 10, 8) }
    private let today = DueDate(year: 2026, month: 10, day: 8)

    private func makeSUT(initialTitle: String = "") -> (viewModel: AddTodoItemViewModel, spy: TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        let provider = DateProviderStub(current: now)
        let viewModel = AddTodoItemViewModel(
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            dateProvider: provider,
            calendar: calendar,
            initialTitle: initialTitle
        )
        return (viewModel, spy)
    }

    @Test func startsWithTheDesignDefaults() {
        let (viewModel, _) = makeSUT()
        #expect(viewModel.title.isEmpty && viewModel.details.isEmpty)
        #expect(viewModel.category == .personal)
        #expect(viewModel.dueDate == today)
        #expect(viewModel.categories == Category.defaults)
    }

    @Test func titleCanBePrefilledFromQuickAdd() {
        #expect(makeSUT(initialTitle: "Call mom").viewModel.title == "Call mom")
    }

    @Test func saveIsDisabledUntilTheTitleHasContent() {
        let (viewModel, _) = makeSUT()
        #expect(!viewModel.canSave)
        viewModel.title = "   "
        #expect(!viewModel.canSave)
        viewModel.title = "Buy milk"
        #expect(viewModel.canSave)
    }

    @Test func titleInputIsLimitedToTheMaximumLength() {
        let (viewModel, _) = makeSUT()
        viewModel.title = String(repeating: "a", count: TodoItemTitle.maxLength + 20)
        #expect(viewModel.title.count == TodoItemTitle.maxLength)
    }

    @Test func savingStoresTheFormValuesAndReportsSuccess() async {
        let (viewModel, spy) = makeSUT()
        viewModel.title = "Call the dentist"
        viewModel.details = "Friday"
        viewModel.category = .work
        viewModel.selectTomorrow()

        let saved = await viewModel.save()

        #expect(saved)
        let item = spy.storedItems.first
        #expect(spy.storedItems.count == 1)
        #expect(item?.title.value == "Call the dentist")
        #expect(item?.description == "Friday")
        #expect(item?.category == .work)
        #expect(item?.dueDate == DueDate(year: 2026, month: 10, day: 9))
        #expect(!viewModel.saveFailed)
    }

    @Test func savingWithoutADueDateStoresNone() async {
        let (viewModel, spy) = makeSUT()
        viewModel.title = "Someday"
        viewModel.clearDueDate()
        _ = await viewModel.save()
        #expect(spy.storedItems.first?.dueDate == nil)
    }

    @Test func savingABlankTitleDoesNothing() async {
        let (viewModel, spy) = makeSUT()
        viewModel.title = "  "
        let saved = await viewModel.save()
        #expect(!saved)
        #expect(spy.storedItems.isEmpty)
    }

    @Test func aRepositoryFailureReportsFailureAndAllowsRetry() async {
        let (viewModel, spy) = makeSUT()
        viewModel.title = "Buy milk"
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        #expect(await viewModel.save() == false)
        #expect(viewModel.saveFailed)
        #expect(!viewModel.isSaving)

        spy.errorToThrow = nil
        #expect(await viewModel.save())
        #expect(!viewModel.saveFailed)
    }

    @Test func quickDateOptionsSetTheDueDate() {
        let (viewModel, _) = makeSUT()
        viewModel.selectTomorrow()
        #expect(viewModel.dueDate == DueDate(year: 2026, month: 10, day: 9))
        viewModel.selectNextWeek()
        #expect(viewModel.dueDate == DueDate(year: 2026, month: 10, day: 15))
        viewModel.selectToday()
        #expect(viewModel.dueDate == today)
    }

    @Test func selectedQuickOptionFollowsTheDueDate() {
        let (viewModel, _) = makeSUT()
        #expect(viewModel.selectedQuickDate == .today)
        viewModel.selectTomorrow()
        #expect(viewModel.selectedQuickDate == .tomorrow)
        viewModel.selectNextWeek()
        #expect(viewModel.selectedQuickDate == .nextWeek)
        viewModel.dueDate = DueDate(year: 2026, month: 12, day: 25)
        #expect(viewModel.selectedQuickDate == nil)
        viewModel.clearDueDate()
        #expect(viewModel.selectedQuickDate == nil)
    }

    @Test func dueDateLabelReflectsTheSelection() {
        let (viewModel, _) = makeSUT()
        #expect(viewModel.dueDateText == "Today, Oct 8")
        viewModel.clearDueDate()
        #expect(viewModel.dueDateText == "No due date")
    }
}
