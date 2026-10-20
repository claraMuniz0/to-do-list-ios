struct AppDependencies {
    let todoItemRepository: TodoItemRepository
    let dateProvider: DateProvider

    static func live() -> AppDependencies {
        AppDependencies(
            todoItemRepository: InMemoryTodoItemRepository(),
            dateProvider: SystemDateProvider()
        )
    }
}
