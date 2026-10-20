/// Repository errors propagate unchanged; the caller decides how to present a failure.
struct GetTodoItemsUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    func execute() async throws -> [TodoItem] {
        try await repository.allTasks()
    }
}
