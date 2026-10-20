enum TodoItemRepositoryError: Error, Equatable {
    case alreadyExists
    case notFound
}

/// Async and throwing so a persistent store can replace the in-memory one without changing Domain.
///
/// - `add` throws `.alreadyExists` for a duplicate id; `update` and `delete` throw `.notFound` for an unknown id.
protocol TodoItemRepository {
    func add(_ item: TodoItem) async throws
    func update(_ item: TodoItem) async throws
    func delete(id: TodoItemID) async throws
    func task(id: TodoItemID) async throws -> TodoItem?
    func allTasks() async throws -> [TodoItem]
}
