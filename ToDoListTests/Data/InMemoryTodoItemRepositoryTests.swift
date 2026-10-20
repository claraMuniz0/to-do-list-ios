import Testing
@testable import MyApp

struct InMemoryTodoItemRepositoryTests {
    @Test func startsEmpty() async throws {
        let repository = InMemoryTodoItemRepository()
        #expect(try await repository.allTasks().isEmpty)
    }

    @Test func addThenFindByID() async throws {
        let repository = InMemoryTodoItemRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        #expect(try await repository.task(id: item.id) == item)
    }

    @Test func allTasksKeepsInsertionOrder() async throws {
        let repository = InMemoryTodoItemRepository()
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        try await repository.add(first)
        try await repository.add(second)
        #expect(try await repository.allTasks() == [first, second])
    }

    @Test func addingDuplicateIDThrows() async throws {
        let repository = InMemoryTodoItemRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        await #expect(throws: TodoItemRepositoryError.alreadyExists) {
            try await repository.add(item)
        }
    }

    @Test func unknownIDReturnsNil() async throws {
        let repository = InMemoryTodoItemRepository()
        #expect(try await repository.task(id: TodoItemID()) == nil)
    }

    @Test func updateReplacesTheStoredItemInPlace() async throws {
        let repository = InMemoryTodoItemRepository()
        var first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        try await repository.add(first)
        try await repository.add(second)
        first.changeCategory(.work)
        try await repository.update(first)
        #expect(try await repository.allTasks() == [first, second])
    }

    @Test func updatingUnknownItemThrows() async throws {
        let repository = InMemoryTodoItemRepository()
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await repository.update(makeTodoItem())
        }
    }

    @Test func deleteRemovesTheItem() async throws {
        let repository = InMemoryTodoItemRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        try await repository.delete(id: item.id)
        #expect(try await repository.allTasks().isEmpty)
    }

    @Test func deletingUnknownItemThrows() async throws {
        let repository = InMemoryTodoItemRepository()
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await repository.delete(id: TodoItemID())
        }
    }
}
