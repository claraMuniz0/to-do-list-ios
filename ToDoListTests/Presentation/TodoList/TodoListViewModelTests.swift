import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoListViewModelTests {
    private func makeSUT(
        items: [TodoItem] = [],
        error: Error? = nil,
        sortOrders: SortOrderRepositorySpy = SortOrderRepositorySpy(),
        minimumLaunchDuration: Duration = .zero
    ) -> (viewModel: TodoListViewModel, spy: TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        spy.storedItems = items
        spy.errorToThrow = error
        let provider = DateProviderStub(current: Date(timeIntervalSince1970: 50_000))
        let viewModel = TodoListViewModel(
            getTodoItems: GetTodoItemsUseCase(repository: spy),
            toggleCompletion: ToggleTodoItemCompletionUseCase(repository: spy, dateProvider: provider),
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: .utcGregorian),
            restoreTodoItem: RestoreTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getSortOrder: GetSortOrderUseCase(repository: sortOrders),
            saveSortOrder: SaveSortOrderUseCase(repository: sortOrders),
            minimumLaunchDuration: minimumLaunchDuration
        )
        return (viewModel, spy)
    }

    @Test func startsInTheLoadingState() {
        #expect(makeSUT().viewModel.state == .loading)
    }

    @Test func isLaunchingBeforeTheFirstLoad() {
        #expect(makeSUT().viewModel.isLaunching)
    }

    @Test func stopsLaunchingOnceTheFirstLoadSucceeds() async {
        let (viewModel, _) = makeSUT(items: [makeTodoItem(title: "A")])
        await viewModel.load()
        #expect(!viewModel.isLaunching)
    }

    @Test func stopsLaunchingWhenTheFirstLoadFails() async {
        let (viewModel, _) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        #expect(!viewModel.isLaunching)
    }

    @Test func theFirstLoadTakesAtLeastTheMinimumLaunchDurationEvenWhenInstant() async {
        let (viewModel, _) = makeSUT(minimumLaunchDuration: .milliseconds(300))

        let elapsed = await ContinuousClock().measure { await viewModel.load() }

        #expect(elapsed >= .milliseconds(300))
        #expect(!viewModel.isLaunching)
    }

    @Test func theStateIsReadyWhileTheSplashIsStillHeld() async {
        let (viewModel, _) = makeSUT(minimumLaunchDuration: .milliseconds(300))

        let task = Task { await viewModel.load() }
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.state == .empty)
        #expect(viewModel.isLaunching)
        await task.value
    }

    @Test func aFailedFirstLoadAlsoHoldsTheSplash() async {
        let (viewModel, _) = makeSUT(error: TodoItemRepositoryError.notFound, minimumLaunchDuration: .milliseconds(300))

        let elapsed = await ContinuousClock().measure { await viewModel.load() }

        #expect(elapsed >= .milliseconds(300))
        #expect(viewModel.state == .error)
    }

    @Test func laterLoadsAndRetriesDoNotWaitAgain() async {
        let (viewModel, _) = makeSUT(minimumLaunchDuration: .milliseconds(300))
        await viewModel.load()

        let elapsed = await ContinuousClock().measure {
            await viewModel.load()
            await viewModel.retry()
        }

        #expect(elapsed < .milliseconds(150))
    }

    @Test func retryDoesNotBringTheSplashBack() async {
        let (viewModel, spy) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        spy.errorToThrow = nil

        await viewModel.retry()

        #expect(!viewModel.isLaunching)
    }

    @Test func loadingWithNoTasksEndsEmpty() async {
        let (viewModel, _) = makeSUT()
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func loadingWithTasksEndsLoadedWithThem() async {
        let items = [makeTodoItem(title: "A"), makeTodoItem(title: "B")]
        let (viewModel, _) = makeSUT(items: items)
        await viewModel.load()
        #expect(viewModel.state == .loaded(TodoListSections(items: items)))
    }

    @Test func aRepositoryFailureEndsInTheErrorState() async {
        let (viewModel, _) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        #expect(viewModel.state == .error)
    }

    @Test func retryRecoversOnceTheRepositoryWorksAgain() async {
        let (viewModel, spy) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        spy.errorToThrow = nil

        await viewModel.retry()

        #expect(viewModel.state == .empty)
        #expect(spy.allTasksCallCount == 2)
    }

    @Test func retryThatFailsAgainStaysInTheErrorState() async {
        let (viewModel, _) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        await viewModel.retry()
        #expect(viewModel.state == .error)
    }

    @Test func retryShowsLoadingWhileReloading() async {
        let (viewModel, spy) = makeSUT(error: TodoItemRepositoryError.notFound)
        await viewModel.load()
        spy.errorToThrow = nil
        var stateDuringReload: TodoListViewState?
        spy.onAllTasks = { stateDuringReload = viewModel.state }

        await viewModel.retry()

        #expect(stateDuringReload == .loading)
    }

    @Test func anyThrownErrorEndsInTheErrorState() async {
        struct UnrelatedError: Error {}
        let (viewModel, _) = makeSUT(error: UnrelatedError())
        await viewModel.load()
        #expect(viewModel.state == .error)
    }

    @Test func aFailingReloadDropsPreviouslyLoadedItems() async {
        let (viewModel, spy) = makeSUT(items: [makeTodoItem()])
        await viewModel.load()
        spy.errorToThrow = TodoItemRepositoryError.notFound

        await viewModel.load()

        #expect(viewModel.state == .error)
    }

    @Test func reloadingAfterTheLastTaskIsGoneEndsEmpty() async {
        let (viewModel, spy) = makeSUT(items: [makeTodoItem()])
        await viewModel.load()
        spy.storedItems = []

        await viewModel.retry()

        #expect(viewModel.state == .empty)
    }

    // MARK: - Sections and subtitle

    @Test func loadedStateSplitsOpenAndCompletedItems() async {
        var done = makeTodoItem(title: "Done")
        done.complete(at: Date(timeIntervalSince1970: 5))
        let (viewModel, _) = makeSUT(items: [makeTodoItem(title: "Open"), done])
        await viewModel.load()
        guard case .loaded(let sections) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(sections.todo.map(\.title.value) == ["Open"])
        #expect(sections.completed.map(\.title.value) == ["Done"])
    }

    @Test func subtitleCountsAllOpenTasksWithPluralisation() async {
        var done = makeTodoItem(title: "Done")
        done.complete(at: Date(timeIntervalSince1970: 5))
        let (viewModel, spy) = makeSUT(items: [makeTodoItem(title: "A"), makeTodoItem(title: "B"), done])
        await viewModel.load()
        #expect(viewModel.subtitle == "2 tasks left")

        spy.storedItems = [makeTodoItem(title: "A"), done]
        await viewModel.load()
        #expect(viewModel.subtitle == "1 task left")

        spy.storedItems = [done]
        await viewModel.load()
        #expect(viewModel.subtitle == "All done")
    }

    // MARK: - Toggle

    @Test func togglingMovesAnOpenTaskToCompleted() async {
        let item = makeTodoItem(title: "A")
        let (viewModel, spy) = makeSUT(items: [item])
        await viewModel.load()

        await viewModel.toggle(id: item.id)

        guard case .loaded(let sections) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(sections.todo.isEmpty)
        #expect(sections.completed.map(\.id) == [item.id])
        #expect(spy.updatedItems.count == 1)
    }

    @Test func togglingACompletedTaskReopensIt() async {
        var item = makeTodoItem(title: "A")
        item.complete(at: Date(timeIntervalSince1970: 5))
        let (viewModel, _) = makeSUT(items: [item])
        await viewModel.load()

        await viewModel.toggle(id: item.id)

        guard case .loaded(let sections) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(sections.todo.map(\.id) == [item.id])
    }

    @Test func aFailedToggleKeepsTheListAndFlagsTheFailure() async {
        let (viewModel, _) = makeSUT(items: [makeTodoItem(title: "A")])
        await viewModel.load()

        await viewModel.toggle(id: TodoItemID())

        #expect(viewModel.actionFailed)
        guard case .loaded(let sections) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(sections.todo.count == 1)
    }

    @Test func aSuccessfulActionClearsThePreviousFailure() async {
        let item = makeTodoItem(title: "A")
        let (viewModel, _) = makeSUT(items: [item])
        await viewModel.load()
        await viewModel.toggle(id: TodoItemID())

        await viewModel.toggle(id: item.id)

        #expect(!viewModel.actionFailed)
    }

    // MARK: - Quick add

    @Test func quickAddStoresATaskAndShowsItInTheList() async {
        let (viewModel, spy) = makeSUT(items: [makeTodoItem(title: "Existing")])
        await viewModel.load()

        let added = await viewModel.quickAdd(title: " Pay rent ")

        #expect(added)
        #expect(spy.storedItems.last?.title.value == "Pay rent")
        guard case .loaded(let sections) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(sections.todo.count == 2)
    }

    @Test func quickAddIgnoresABlankTitle() async {
        let (viewModel, spy) = makeSUT(items: [makeTodoItem(title: "Existing")])
        await viewModel.load()

        #expect(await viewModel.quickAdd(title: "  ") == false)
        #expect(spy.storedItems.count == 1)
        #expect(!viewModel.actionFailed)
    }

    @Test func quickAddFailureIsFlaggedWithoutLosingTheList() async {
        let (viewModel, spy) = makeSUT(items: [makeTodoItem(title: "Existing")])
        await viewModel.load()
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists
        spy.onAllTasks = { spy.errorToThrow = nil }

        #expect(await viewModel.quickAdd(title: "New") == false)
        #expect(viewModel.actionFailed)
    }

    // MARK: - Undo delete

    @Test func startsWithoutAnUndo() {
        #expect(makeSUT().viewModel.undoState == nil)
    }

    @Test func aDeletedItemOffersUndoAndTheListNoLongerShowsIt() async {
        let kept = makeTodoItem(title: "Kept")
        let (viewModel, _) = makeSUT(items: [kept])
        let deleted = makeTodoItem(title: "Deleted")

        await viewModel.didDelete(deleted)

        #expect(viewModel.undoState == UndoState(item: deleted))
        #expect(viewModel.state == .loaded(TodoListSections(items: [kept])))
    }

    @Test func aSecondDeleteReplacesTheToastAndMakesTheFirstFinal() async {
        let (viewModel, spy) = makeSUT()
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")

        await viewModel.didDelete(first)
        await viewModel.didDelete(second)
        await viewModel.undo()

        #expect(spy.storedItems == [second])
        #expect(viewModel.undoState == nil)
    }

    @Test func undoRestoresTheSameItemAndClearsTheToast() async {
        var deleted = makeTodoItem(title: "Deleted", description: "Text", createdAt: Date(timeIntervalSince1970: 7))
        deleted.complete(at: Date(timeIntervalSince1970: 9))
        let (viewModel, spy) = makeSUT()
        await viewModel.didDelete(deleted)

        await viewModel.undo()

        #expect(spy.storedItems == [deleted])
        #expect(viewModel.undoState == nil)
        #expect(viewModel.state == .loaded(TodoListSections(items: [deleted])))
        #expect(!viewModel.actionFailed)
    }

    @Test func aFailedUndoFlagsTheFailureAndClosesTheToast() async {
        let deleted = makeTodoItem()
        let (viewModel, spy) = makeSUT()
        await viewModel.didDelete(deleted)
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        await viewModel.undo()

        #expect(spy.storedItems.isEmpty)
        #expect(viewModel.actionFailed)
        #expect(viewModel.undoState == nil)
    }

    @Test func dismissingTheToastKeepsTheDeleteFinal() async {
        let (viewModel, spy) = makeSUT()
        await viewModel.didDelete(makeTodoItem())

        viewModel.dismissUndo()
        await viewModel.undo()

        #expect(viewModel.undoState == nil)
        #expect(spy.storedItems.isEmpty)
    }

    @Test func undoWithNothingToUndoDoesNothing() async {
        let (viewModel, spy) = makeSUT()
        await viewModel.undo()
        #expect(spy.storedItems.isEmpty)
        #expect(!viewModel.actionFailed)
    }

    // MARK: - Filters

    private func completedItem(_ title: String, category: Category = .personal) -> TodoItem {
        var item = makeTodoItem(title: title, category: category)
        item.complete(at: Date(timeIntervalSince1970: 5))
        return item
    }

    private func loadedSUT(_ items: [TodoItem]) async -> (viewModel: TodoListViewModel, spy: TodoItemRepositorySpy) {
        let sut = makeSUT(items: items)
        await sut.viewModel.load()
        return sut
    }

    @Test func startsWithTheAllFilter() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        #expect(viewModel.selectedFilter == .all)
    }

    @Test func visibleSectionsFollowTheSelectedFilter() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem(title: "Open"), completedItem("Done")])

        viewModel.select(.done)
        #expect(viewModel.visibleSections.todo.isEmpty)
        #expect(viewModel.visibleSections.completed.map(\.title.value) == ["Done"])

        viewModel.select(.active)
        #expect(viewModel.visibleSections.todo.map(\.title.value) == ["Open"])
        #expect(viewModel.visibleSections.completed.isEmpty)
    }

    @Test func theFilterSurvivesAReload() async {
        let (viewModel, spy) = await loadedSUT([makeTodoItem(title: "Open"), completedItem("Done")])
        viewModel.select(.done)
        spy.storedItems.append(makeTodoItem(title: "New"))

        await viewModel.load()

        #expect(viewModel.selectedFilter == .done)
        #expect(viewModel.visibleSections.completed.map(\.title.value) == ["Done"])
    }

    @Test func visibleSectionsAreEmptyWhenNotLoaded() {
        let viewModel = makeSUT().viewModel
        #expect(viewModel.visibleSections == TodoListSections(items: []))
    }

    // MARK: - Categories panel

    @Test func togglingTheCategoriesPillPreselectsWorkAndOpensThePanel() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.toggleCategories()
        #expect(viewModel.selectedFilter == .category(.work))
        #expect(viewModel.isCategoriesPanelOpen)
    }

    @Test func togglingTheCategoriesPillAgainReturnsToAll() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.toggleCategories()
        viewModel.toggleCategories()
        #expect(viewModel.selectedFilter == .all)
        #expect(!viewModel.isCategoriesPanelOpen)
    }

    @Test func selectingAnotherCategoryKeepsThePanelOpen() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.toggleCategories()
        viewModel.selectCategory(.shopping)
        #expect(viewModel.selectedFilter == .category(.shopping))
        #expect(viewModel.isCategoriesPanelOpen)
    }

    @Test func selectingTheSelectedCategoryAgainFallsBackToAll() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.selectCategory(.personal)
        viewModel.selectCategory(.personal)
        #expect(viewModel.selectedFilter == .all)
        #expect(!viewModel.isCategoriesPanelOpen)
    }

    @Test func choosingAnotherPillClosesThePanel() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.toggleCategories()
        viewModel.select(.active)
        #expect(!viewModel.isCategoriesPanelOpen)
    }

    @Test func categoryCountsListEveryDefaultCategoryWithItsOpenTasksOnly() async {
        let (viewModel, _) = await loadedSUT([
            makeTodoItem(category: .work), makeTodoItem(category: .work),
            completedItem("Done work", category: .work), makeTodoItem(category: .personal),
        ])
        #expect(viewModel.categoryCounts == [
            CategoryCount(category: .work, openCount: 2),
            CategoryCount(category: .personal, openCount: 1),
            CategoryCount(category: .shopping, openCount: 0),
        ])
    }

    @Test func categoryCountsAreZeroWhenNotLoaded() {
        #expect(makeSUT().viewModel.categoryCounts.map(\.openCount) == [0, 0, 0])
    }

    // MARK: - All caught up

    @Test func allCaughtUpWhenEveryTaskIsCompleted() async {
        let (viewModel, _) = await loadedSUT([completedItem("A"), completedItem("B")])
        #expect(viewModel.isAllCaughtUp)
        viewModel.select(.active)
        #expect(viewModel.isAllCaughtUp)
    }

    @Test func notAllCaughtUpWithAnOpenTask() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem(), completedItem("B")])
        #expect(!viewModel.isAllCaughtUp)
    }

    @Test func notAllCaughtUpUnderTheDoneOrCategoryFilters() async {
        let (viewModel, _) = await loadedSUT([completedItem("A")])
        viewModel.select(.done)
        #expect(!viewModel.isAllCaughtUp)
        viewModel.select(.category(.work))
        #expect(!viewModel.isAllCaughtUp)
    }

    @Test func notAllCaughtUpWithoutTasksOrBeforeLoading() async {
        #expect(!makeSUT().viewModel.isAllCaughtUp)
        let (viewModel, _) = await loadedSUT([])
        #expect(!viewModel.isAllCaughtUp)
    }

    @Test func allCaughtUpCopyUsesTheTotalTaskCount() async {
        let (viewModel, _) = await loadedSUT([completedItem("A"), completedItem("B")])
        #expect(viewModel.allCaughtUpMessage == "You finished 2 of 2 tasks. Enjoy the break!")
        #expect(viewModel.viewCompletedTitle == "View completed (2)")
    }

    @Test func allCaughtUpCopyHandlesASingleTask() async {
        let (viewModel, _) = await loadedSUT([completedItem("A")])
        #expect(viewModel.allCaughtUpMessage == "You finished 1 of 1 task. Enjoy the break!")
        #expect(viewModel.viewCompletedTitle == "View completed (1)")
    }

    @Test func viewCompletedSwitchesToTheDoneFilter() async {
        let (viewModel, _) = await loadedSUT([completedItem("A")])
        viewModel.viewCompleted()
        #expect(viewModel.selectedFilter == .done)
    }

    @Test func completingTheLastOpenTaskLeadsToAllCaughtUp() async {
        let item = makeTodoItem()
        let (viewModel, _) = await loadedSUT([item])
        await viewModel.toggle(id: item.id)
        #expect(viewModel.isAllCaughtUp)
    }

    @Test func undoingAfterAllCaughtUpBringsTheOpenTaskBack() async {
        let open = makeTodoItem(title: "Open")
        let (viewModel, spy) = await loadedSUT([open, completedItem("Done")])
        spy.storedItems = [completedItem("Done")]
        await viewModel.didDelete(open)
        #expect(viewModel.isAllCaughtUp)

        await viewModel.undo()

        #expect(!viewModel.isAllCaughtUp)
    }

    // MARK: - Empty filter messages

    @Test func doneFilterWithoutCompletedTasksExplainsItself() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.select(.done)
        #expect(viewModel.emptyFilterMessage == "Nothing completed yet")
    }

    @Test func categoryWithoutOpenTasksNamesTheCategory() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem(category: .personal), completedItem("Done", category: .work)])
        viewModel.select(.category(.work))
        #expect(viewModel.emptyFilterMessage == "No open tasks in Work")
    }

    @Test func noMessageWhileTheFilterHasContent() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem(category: .work), completedItem("Done")])
        for filter in [TodoListFilter.all, .active, .done, .category(.work)] {
            viewModel.select(filter)
            #expect(viewModel.emptyFilterMessage == nil)
        }
    }

    @Test func noMessageWhenAllCaughtUpOrNotLoaded() async {
        #expect(makeSUT().viewModel.emptyFilterMessage == nil)
        let (viewModel, _) = await loadedSUT([completedItem("A")])
        viewModel.select(.active)
        #expect(viewModel.isAllCaughtUp)
        #expect(viewModel.emptyFilterMessage == nil)
    }

    // MARK: - Swipe delete

    @Test func deletingByIDRemovesTheTaskAndOffersUndo() async {
        let doomed = makeTodoItem(title: "Doomed")
        let kept = makeTodoItem(title: "Kept")
        let (viewModel, spy) = await loadedSUT([doomed, kept])

        await viewModel.delete(id: doomed.id)

        #expect(spy.storedItems == [kept])
        #expect(viewModel.undoState == UndoState(item: doomed))
        #expect(viewModel.state == .loaded(TodoListSections(items: [kept])))
        #expect(!viewModel.actionFailed)
    }

    @Test func deletingACompletedTaskAlsoOffersUndo() async {
        let done = completedItem("Done")
        let (viewModel, _) = await loadedSUT([done])
        await viewModel.delete(id: done.id)
        #expect(viewModel.undoState == UndoState(item: done))
    }

    @Test func undoAfterASwipeDeleteBringsTheTaskBack() async {
        let item = makeTodoItem(title: "Back")
        let (viewModel, spy) = await loadedSUT([item])
        await viewModel.delete(id: item.id)

        await viewModel.undo()

        #expect(spy.storedItems == [item])
        #expect(viewModel.undoState == nil)
    }

    @Test func aSecondSwipeDeleteReplacesTheToast() async {
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        let (viewModel, _) = await loadedSUT([first, second])

        await viewModel.delete(id: first.id)
        await viewModel.delete(id: second.id)

        #expect(viewModel.undoState == UndoState(item: second))
    }

    @Test func aFailedDeleteFlagsTheFailureAndKeepsTheTask() async {
        let item = makeTodoItem()
        let (viewModel, spy) = await loadedSUT([item])
        spy.deleteError = StubFailure()

        await viewModel.delete(id: item.id)

        #expect(viewModel.actionFailed)
        #expect(viewModel.undoState == nil)
        #expect(spy.storedItems == [item])
        #expect(viewModel.state == .loaded(TodoListSections(items: [item])))
    }

    @Test func deletingAnUnknownIDFlagsTheFailure() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        await viewModel.delete(id: TodoItemID())
        #expect(viewModel.actionFailed)
        #expect(viewModel.undoState == nil)
    }

    @Test func deletingTheLastTaskEndsInTheEmptyState() async {
        let item = makeTodoItem()
        let (viewModel, _) = await loadedSUT([item])
        await viewModel.delete(id: item.id)
        #expect(viewModel.state == .empty)
        #expect(viewModel.undoState == UndoState(item: item))
    }

    // MARK: - Review follow-ups

    @Test func aFailedDeleteLeavesThePreviousToastAlone() async {
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        let (viewModel, spy) = await loadedSUT([first, second])
        await viewModel.delete(id: first.id)
        spy.deleteError = StubFailure()

        await viewModel.delete(id: second.id)

        #expect(viewModel.actionFailed)
        #expect(viewModel.undoState == UndoState(item: first))
    }

    @Test func aSuccessfulDeleteClearsAnEarlierFailure() async {
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        let (viewModel, spy) = await loadedSUT([first, second])
        spy.deleteError = StubFailure()
        await viewModel.delete(id: first.id)
        spy.deleteError = nil

        await viewModel.delete(id: second.id)

        #expect(!viewModel.actionFailed)
    }

    @Test func togglingCategoriesFromAnotherFilterOpensThePanelOnWork() async {
        let (viewModel, _) = await loadedSUT([makeTodoItem()])
        viewModel.select(.done)
        viewModel.toggleCategories()
        #expect(viewModel.selectedFilter == .category(.work))
    }

    @Test func deletingTheLastOpenTaskOfTheSelectedCategoryShowsItsEmptyMessage() async {
        let only = makeTodoItem(category: .work)
        let (viewModel, _) = await loadedSUT([only, makeTodoItem(category: .personal)])
        viewModel.select(.category(.work))
        #expect(viewModel.emptyFilterMessage == nil)

        await viewModel.delete(id: only.id)

        #expect(viewModel.emptyFilterMessage == "No open tasks in Work")
    }

    @Test func noFilterMessagesInTheEmptyOrErrorStates() async {
        let (empty, _) = await loadedSUT([])
        empty.select(.done)
        #expect(empty.emptyFilterMessage == nil)
        #expect(!empty.isAllCaughtUp)

        let failing = makeSUT(error: StubFailure()).viewModel
        await failing.load()
        failing.select(.category(.work))
        #expect(failing.emptyFilterMessage == nil)
        #expect(!failing.isAllCaughtUp)
    }

    private func titles(_ items: [TodoItem]) -> [String] { items.map(\.title.value) }

    @Test func startsWithTheDefaultSortOrder() {
        #expect(makeSUT().viewModel.sortOrder == .dueDate)
    }

    @Test func startsWithTheRememberedSortOrder() {
        let sortOrders = SortOrderRepositorySpy(stored: .titleAZ)
        #expect(makeSUT(sortOrders: sortOrders).viewModel.sortOrder == .titleAZ)
    }

    @Test func loadingOrdersOpenTasksByTheRememberedSortOrder() async {
        let items = [makeTodoItem(title: "B"), makeTodoItem(title: "A")]
        let (viewModel, _) = makeSUT(items: items, sortOrders: SortOrderRepositorySpy(stored: .titleAZ))
        await viewModel.load()
        #expect(titles(viewModel.visibleSections.todo) == ["A", "B"])
    }

    @Test func choosingASortOrderReordersTheLoadedListWithoutReloading() async {
        let items = [
            makeTodoItem(title: "Old", createdAt: Date(timeIntervalSince1970: 1)),
            makeTodoItem(title: "New", createdAt: Date(timeIntervalSince1970: 2)),
        ]
        let (viewModel, spy) = makeSUT(items: items)
        await viewModel.load()

        viewModel.selectSortOrder(.newestFirst)

        #expect(viewModel.sortOrder == .newestFirst)
        #expect(titles(viewModel.visibleSections.todo) == ["New", "Old"])
        #expect(spy.allTasksCallCount == 1)
    }

    @Test func choosingASortOrderKeepsTheSelectedFilterAndSorts() async {
        let items = [
            makeTodoItem(title: "Old", createdAt: Date(timeIntervalSince1970: 1)),
            makeTodoItem(title: "New", createdAt: Date(timeIntervalSince1970: 2)),
        ]
        let (viewModel, _) = makeSUT(items: items)
        await viewModel.load()
        viewModel.select(.active)

        viewModel.selectSortOrder(.newestFirst)

        #expect(viewModel.selectedFilter == .active)
        #expect(titles(viewModel.visibleSections.todo) == ["New", "Old"])
    }

    @Test func choosingASortOrderRemembersIt() {
        let sortOrders = SortOrderRepositorySpy()
        makeSUT(sortOrders: sortOrders).viewModel.selectSortOrder(.newestFirst)
        #expect(sortOrders.stored == .newestFirst)
    }

    @Test func choosingTheActiveSortOrderAgainDoesNotSaveAgain() {
        let sortOrders = SortOrderRepositorySpy()
        makeSUT(sortOrders: sortOrders).viewModel.selectSortOrder(.dueDate)
        #expect(sortOrders.saveCallCount == 0)
    }

    @Test func theSortOrderSurvivesReloads() async {
        let (viewModel, _) = makeSUT(items: [makeTodoItem(title: "B"), makeTodoItem(title: "A")])
        await viewModel.load()
        viewModel.selectSortOrder(.titleAZ)
        await viewModel.load()
        #expect(titles(viewModel.visibleSections.todo) == ["A", "B"])
    }
}
