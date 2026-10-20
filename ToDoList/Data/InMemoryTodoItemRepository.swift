actor InMemoryTodoItemRepository: TodoItemRepository {
    private var items: [TodoItem] = []

    func add(_ item: TodoItem) throws {
        guard !items.contains(where: { $0.id == item.id }) else {
            throw TodoItemRepositoryError.alreadyExists
        }
        items.append(item)
    }

    func update(_ item: TodoItem) throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw TodoItemRepositoryError.notFound
        }
        items[index] = item
    }

    func delete(id: TodoItemID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw TodoItemRepositoryError.notFound
        }
        items.remove(at: index)
    }

    func task(id: TodoItemID) -> TodoItem? {
        items.first { $0.id == id }
    }

    func allTasks() -> [TodoItem] {
        items
    }
}
