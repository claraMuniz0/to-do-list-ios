/// Deletes immediately and returns the removed item so the caller can offer Undo through `RestoreTodoItemUseCase`.
/// - Throws: `TodoItemRepositoryError.notFound` for an unknown id.
struct DeleteTodoItemUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(id: TodoItemID) async throws -> TodoItem {
        guard let item = try await repository.task(id: id) else { throw TodoItemRepositoryError.notFound }
        try await repository.delete(id: id)
        return item
    }
}
