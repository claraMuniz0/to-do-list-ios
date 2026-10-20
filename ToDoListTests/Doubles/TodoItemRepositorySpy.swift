@testable import MyApp

final class TodoItemRepositorySpy: TodoItemRepository {
    var storedItems: [TodoItem] = []
    var errorToThrow: Error?
    var onAllTasks: (() -> Void)?
    private(set) var allTasksCallCount = 0

    func add(_ item: TodoItem) async throws {
        if let errorToThrow { throw errorToThrow }
        storedItems.append(item)
    }

    func update(_ item: TodoItem) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func delete(id: TodoItemID) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func task(id: TodoItemID) async throws -> TodoItem? {
        if let errorToThrow { throw errorToThrow }
        return storedItems.first { $0.id == id }
    }

    func allTasks() async throws -> [TodoItem] {
        allTasksCallCount += 1
        onAllTasks?()
        if let errorToThrow { throw errorToThrow }
        return storedItems
    }
}
