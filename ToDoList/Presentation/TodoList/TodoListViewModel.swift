import Observation

/// `.loading` is the initial state so the Welcome screen never flashes for users who already have tasks.
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

    /// Any thrown error ends in `.error`; previously loaded items are dropped rather than shown stale.
    func load() async {
        do {
            let items = try await getTodoItems.execute()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error
        }
    }

    /// Goes back through `.loading` first so the error view disappears while the reload runs.
    func retry() async {
        state = .loading
        await load()
    }
}
