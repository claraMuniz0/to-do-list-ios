/// Loads one item, for the Edit form to prefill from.
/// - Throws: `TodoItemRepositoryError.notFound` for an unknown id.
struct GetTodoItemUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    func execute(id: TodoItemID) async throws -> TodoItem {
        guard let item = try await repository.task(id: id) else { throw TodoItemRepositoryError.notFound }
        return item
    }
}
