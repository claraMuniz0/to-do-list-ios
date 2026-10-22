import Foundation
/// Shared collaborators and the factories that wire view models from them; built only in the composition root.
struct AppDependencies {
    let todoItemRepository: TodoItemRepository
    let dateProvider: DateProvider
    var calendar: Calendar = .current
    var sortOrderRepository: SortOrderRepository = UserDefaultsSortOrderRepository()

    var recentSearchRepository: RecentSearchRepository = UserDefaultsRecentSearchRepository()

    func makeSearchTodoItemsUseCase() -> SearchTodoItemsUseCase { SearchTodoItemsUseCase(repository: todoItemRepository) }
    func makeGetRecentSearchesUseCase() -> GetRecentSearchesUseCase { GetRecentSearchesUseCase(repository: recentSearchRepository) }
    func makeRecordRecentSearchUseCase() -> RecordRecentSearchUseCase { RecordRecentSearchUseCase(repository: recentSearchRepository) }
    func makeClearRecentSearchesUseCase() -> ClearRecentSearchesUseCase { ClearRecentSearchesUseCase(repository: recentSearchRepository) }

    @MainActor
    func makeTodoListViewModel() -> TodoListViewModel {
        TodoListViewModel(
            getTodoItems: GetTodoItemsUseCase(repository: todoItemRepository),
            toggleCompletion: ToggleTodoItemCompletionUseCase(repository: todoItemRepository, dateProvider: dateProvider),
            addTodoItem: makeAddTodoItemUseCase(),
            restoreTodoItem: RestoreTodoItemUseCase(repository: todoItemRepository),
            deleteTodoItem: DeleteTodoItemUseCase(repository: todoItemRepository),
            sortOrderRepository: sortOrderRepository
        )
    }

    @MainActor
    func makeTodoItemFormViewModel(mode: TodoItemFormMode = .add, initialTitle: String = "") -> TodoItemFormViewModel {
        TodoItemFormViewModel(
            mode: mode,
            addTodoItem: makeAddTodoItemUseCase(),
            updateTodoItem: UpdateTodoItemUseCase(repository: todoItemRepository),
            deleteTodoItem: DeleteTodoItemUseCase(repository: todoItemRepository),
            getTodoItem: GetTodoItemUseCase(repository: todoItemRepository),
            dateProvider: dateProvider,
            calendar: calendar,
            initialTitle: initialTitle
        )
    }

    private func makeAddTodoItemUseCase() -> AddTodoItemUseCase {
        AddTodoItemUseCase(repository: todoItemRepository, dateProvider: dateProvider, calendar: calendar)
    }
}
