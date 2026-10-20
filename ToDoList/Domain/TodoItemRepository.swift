enum TodoItemRepositoryError: Error, Equatable {
    case alreadyExists
    case notFound
}

protocol TodoItemRepository {
    func add(_ item: TodoItem) async throws
    func update(_ item: TodoItem) async throws
    func delete(id: TodoItemID) async throws
    func task(id: TodoItemID) async throws -> TodoItem?
    func allTasks() async throws -> [TodoItem]
}
