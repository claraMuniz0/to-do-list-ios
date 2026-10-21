import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoItemFormViewModelTests {
    private let calendar = Calendar.utcGregorian
    private var now: Date { calendar.makeDate(2026, 10, 8) }
    private let today = makeDueDate(2026, 10, 8)

    private func makeSUT(
        mode: TodoItemFormMode = .add,
        initialTitle: String = ""
    ) -> (viewModel: TodoItemFormViewModel, spy: TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        let provider = DateProviderStub(current: now)
        let viewModel = TodoItemFormViewModel(
            mode: mode,
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getTodoItem: GetTodoItemUseCase(repository: spy),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
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
        #expect(item?.dueDate == makeDueDate(2026, 10, 9))
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
        #expect(viewModel.dueDate == makeDueDate(2026, 10, 9))
        viewModel.selectNextWeek()
        #expect(viewModel.dueDate == makeDueDate(2026, 10, 15))
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
        viewModel.dueDate = makeDueDate(2026, 12, 25)
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

    // MARK: - Date sheet inputs

    @Test func exposesTheInjectedCalendarAndTheCurrentInstantForTheDateSheet() {
        let (viewModel, _) = makeSUT()
        #expect(viewModel.calendar == calendar)
        #expect(viewModel.now == now)
    }

    @Test func earliestSelectableDateIsTodayForANewOrFutureDate() {
        let (viewModel, _) = makeSUT()
        #expect(viewModel.earliestSelectableDueDate == today)
        viewModel.selectNextWeek()
        #expect(viewModel.earliestSelectableDueDate == today)
        viewModel.clearDueDate()
        #expect(viewModel.earliestSelectableDueDate == today)
    }

    @Test func earliestSelectableDateKeepsAnAlreadyChosenPastDateReachable() {
        let (viewModel, _) = makeSUT()
        viewModel.dueDate = makeDueDate(2026, 10, 1)
        #expect(viewModel.earliestSelectableDueDate == makeDueDate(2026, 10, 1))
    }

    // MARK: - Edit mode

    private func makeEditSUT(_ item: TodoItem) -> (viewModel: TodoItemFormViewModel, spy: TodoItemRepositorySpy) {
        let sut = makeSUT(mode: .edit(item.id))
        sut.spy.storedItems = [item]
        return sut
    }

    @Test func copyFollowsTheMode() {
        let add = makeSUT().viewModel
        #expect(add.screenSubtitle == "What's on your mind?")
        #expect(add.screenTitle == "New task")
        #expect(add.saveButtonTitle == "Save task")
        #expect(!add.canDelete)

        let edit = makeSUT(mode: .edit(TodoItemID())).viewModel
        #expect(edit.screenSubtitle == "Make it just right")
        #expect(edit.screenTitle == "Edit task")
        #expect(edit.saveButtonTitle == "Save changes")
        #expect(edit.canDelete)
    }

    @Test func loadPrefillsTheFormFromTheStoredItem() async {
        let item = makeTodoItem(
            title: "Buy groceries", description: "Milk, eggs", category: .work, dueDate: makeDueDate(2026, 10, 9)
        )
        let (viewModel, _) = makeEditSUT(item)

        await viewModel.load()

        #expect(viewModel.title == "Buy groceries")
        #expect(viewModel.details == "Milk, eggs")
        #expect(viewModel.category == .work)
        #expect(viewModel.dueDate == makeDueDate(2026, 10, 9))
        #expect(!viewModel.loadFailed)
    }

    @Test func loadKeepsAMissingDueDateAndAPastOneAsStored() async {
        let (noDate, _) = makeEditSUT(makeTodoItem(dueDate: nil))
        await noDate.load()
        #expect(noDate.dueDate == nil)

        let (past, _) = makeEditSUT(makeTodoItem(dueDate: makeDueDate(2026, 10, 1)))
        await past.load()
        #expect(past.dueDate == makeDueDate(2026, 10, 1))
        #expect(past.earliestSelectableDueDate == makeDueDate(2026, 10, 1))
    }

    @Test func loadingAnUnknownItemFlagsTheFailure() async {
        let (viewModel, _) = makeSUT(mode: .edit(TodoItemID()))
        await viewModel.load()
        #expect(viewModel.loadFailed)
    }

    @Test func addModeLoadDoesNothing() async {
        let (viewModel, _) = makeSUT()
        await viewModel.load()
        #expect(!viewModel.loadFailed)
        #expect(viewModel.dueDate == today)
    }

    @Test func savingInEditModeUpdatesTheStoredItemKeepingItsIdentity() async {
        var item = makeTodoItem(title: "Old", description: "Old text", category: .personal)
        item.complete(at: Date(timeIntervalSince1970: 9))
        let (viewModel, spy) = makeEditSUT(item)
        await viewModel.load()
        viewModel.title = "New"
        viewModel.details = ""
        viewModel.category = .work
        viewModel.selectNextWeek()

        let saved = await viewModel.save()

        #expect(saved)
        #expect(spy.storedItems.count == 1)
        let stored = spy.storedItems.first
        #expect(stored?.id == item.id)
        #expect(stored?.title.value == "New")
        #expect(stored?.description == nil)
        #expect(stored?.category == .work)
        #expect(stored?.dueDate == makeDueDate(2026, 10, 15))
        #expect(stored?.completedAt == item.completedAt)
    }

    @Test func savingInEditModeWithABlankTitleDoesNothing() async {
        let item = makeTodoItem(title: "Keep")
        let (viewModel, spy) = makeEditSUT(item)
        await viewModel.load()
        viewModel.title = "  "

        #expect(!viewModel.canSave)
        #expect(await viewModel.save() == false)
        #expect(spy.storedItems == [item])
    }

    @Test func aFailedEditSaveReportsFailureAndKeepsTheFormEditable() async {
        let item = makeTodoItem()
        let (viewModel, spy) = makeEditSUT(item)
        await viewModel.load()
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        #expect(await viewModel.save() == false)
        #expect(viewModel.saveFailed)
        #expect(!viewModel.isSaving)
    }

    @Test func deleteRemovesTheItemAndReturnsItForUndo() async {
        let item = makeTodoItem(title: "Buy milk")
        let (viewModel, spy) = makeEditSUT(item)
        await viewModel.load()

        let deleted = await viewModel.delete()

        #expect(deleted == item)
        #expect(spy.storedItems.isEmpty)
        #expect(!viewModel.deleteFailed)
    }

    @Test func aFailedDeleteReturnsNilAndFlagsTheFailure() async {
        let item = makeTodoItem()
        let (viewModel, spy) = makeEditSUT(item)
        await viewModel.load()
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        #expect(await viewModel.delete() == nil)
        #expect(viewModel.deleteFailed)
        #expect(spy.storedItems == [item])
    }

    @Test func deleteInAddModeDoesNothing() async {
        let (viewModel, spy) = makeSUT()
        spy.storedItems = [makeTodoItem()]

        #expect(await viewModel.delete() == nil)
        #expect(spy.storedItems.count == 1)
    }
}
