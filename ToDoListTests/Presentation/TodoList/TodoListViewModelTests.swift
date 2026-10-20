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
        let viewModel = TodoListViewModel(getTodoItems: GetTodoItemsUseCase(repository: spy))
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
        #expect(viewModel.state == .loaded(items))
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
}
