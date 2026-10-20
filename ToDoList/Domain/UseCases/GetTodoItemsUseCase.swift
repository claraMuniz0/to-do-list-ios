struct GetTodoItemsUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    func execute() async throws -> [TodoItem] {
        try await repository.allTasks()
    }
}
