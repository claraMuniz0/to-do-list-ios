import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoListViewModelTests {
    private func makeSUT(
        items: [TodoItem] = [],
        error: Error? = nil
    ) -> (viewModel: TodoListViewModel, spy: TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        spy.storedItems = items
        spy.errorToThrow = error
        let provider = DateProviderStub(current: Date(timeIntervalSince1970: 50_000))
        let viewModel = TodoListViewModel(
            getTodoItems: GetTodoItemsUseCase(repository: spy),
            toggleCompletion: ToggleTodoItemCompletionUseCase(repository: spy, dateProvider: provider),
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: .utcGregorian)
        )
        return (viewModel, spy)
    }

    @Test func startsInTheLoadingState() {
        #expect(makeSUT().viewModel.state == .loading)
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
        #expect(viewModel.subtitle == "No tasks left")
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
}
