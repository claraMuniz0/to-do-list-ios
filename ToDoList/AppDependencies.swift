import Foundation
/// Shared collaborators and the factories that wire view models from them; built only in the composition root.
struct AppDependencies {
    let todoItemRepository: TodoItemRepository
    let dateProvider: DateProvider
    var calendar: Calendar = .current

    @MainActor
    func makeTodoListViewModel() -> TodoListViewModel {
        TodoListViewModel(
            getTodoItems: GetTodoItemsUseCase(repository: todoItemRepository),
            toggleCompletion: ToggleTodoItemCompletionUseCase(repository: todoItemRepository, dateProvider: dateProvider),
            addTodoItem: makeAddTodoItemUseCase()
        )
    }

    @MainActor
    func makeTodoItemFormViewModel(initialTitle: String = "") -> TodoItemFormViewModel {
        TodoItemFormViewModel(
            addTodoItem: makeAddTodoItemUseCase(),
            dateProvider: dateProvider,
            calendar: calendar,
            initialTitle: initialTitle
        )
    }

    private func makeAddTodoItemUseCase() -> AddTodoItemUseCase {
        AddTodoItemUseCase(repository: todoItemRepository, dateProvider: dateProvider, calendar: calendar)
    }
}
