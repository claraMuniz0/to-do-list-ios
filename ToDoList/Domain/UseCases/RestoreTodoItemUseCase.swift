/// Puts a deleted item back through `add`, keeping its id, `createdAt` and `completedAt` so Undo returns the same task.
/// - Throws: `TodoItemRepositoryError.alreadyExists` if an item with that id is already stored.
struct RestoreTodoItemUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    func execute(_ item: TodoItem) async throws {
        try await repository.add(item)
    }
}
