struct AppDependencies {
    let todoItemRepository: TodoItemRepository
    let dateProvider: DateProvider

    @MainActor
    func makeTodoListViewModel() -> TodoListViewModel {
        TodoListViewModel(getTodoItems: GetTodoItemsUseCase(repository: todoItemRepository))
    }
}
