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

    @Test func failedAddLeavesStateUnchanged() async throws {
        let repository = InMemoryTodoItemRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        _ = try? await repository.add(item)
        #expect(try await repository.allTasks() == [item])
    }

    @Test func failedUpdateLeavesStateUnchanged() async throws {
        let repository = InMemoryTodoItemRepository()
        let stored = makeTodoItem()
        try await repository.add(stored)
        _ = try? await repository.update(makeTodoItem(title: "Ghost"))
        #expect(try await repository.allTasks() == [stored])
    }

    @Test func taskReturnsTheUpdatedValue() async throws {
        let repository = InMemoryTodoItemRepository()
        var item = makeTodoItem()
        try await repository.add(item)
        item.changeCategory(.work)
        try await repository.update(item)
        #expect(try await repository.task(id: item.id)?.category == .work)
    }

    @Test func deleteKeepsTheOthersInOrder() async throws {
        let repository = InMemoryTodoItemRepository()
        let a = makeTodoItem(title: "A"), b = makeTodoItem(title: "B"), c = makeTodoItem(title: "C")
        for item in [a, b, c] { try await repository.add(item) }
        try await repository.delete(id: b.id)
        #expect(try await repository.allTasks() == [a, c])
        #expect(try await repository.task(id: b.id) == nil)
    }

    @Test func deletingTwiceThrowsNotFoundTheSecondTime() async throws {
        let repository = InMemoryTodoItemRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        try await repository.delete(id: item.id)
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await repository.delete(id: item.id)
        }
    }

    @Test func concurrentAddsAreAllStored() async throws {
        let repository = InMemoryTodoItemRepository()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask { try await repository.add(makeTodoItem(title: "Item \(index)")) }
            }
            try await group.waitForAll()
        }
        #expect(try await repository.allTasks().count == 50)
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
