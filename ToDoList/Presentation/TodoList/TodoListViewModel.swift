import Observation

enum TodoListViewState: Equatable {
    case loading
    case empty
    case loaded([TodoItem])
    case error
}

@MainActor @Observable
final class TodoListViewModel {
    private(set) var state: TodoListViewState = .loading

    private let getTodoItems: GetTodoItemsUseCase

    init(getTodoItems: GetTodoItemsUseCase) {
        self.getTodoItems = getTodoItems
    }

    func load() async {
        do {
            let items = try await getTodoItems.execute()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error
        }
    }

    func retry() async {
        state = .loading
        await load()
    }
}
