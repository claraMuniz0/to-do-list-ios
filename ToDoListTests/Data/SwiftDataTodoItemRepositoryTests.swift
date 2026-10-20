import Foundation
import SwiftData
import Testing
@testable import MyApp

@MainActor
struct SwiftDataTodoItemRepositoryTests {
    private func makeRepository(container: ModelContainer? = nil) throws -> SwiftDataTodoItemRepository {
        SwiftDataTodoItemRepository(container: try container ?? .inMemoryTodoItems())
    }

    @Test func startsEmpty() async throws {
        #expect(try await makeRepository().allTasks().isEmpty)
    }

    @Test func addThenFindByID() async throws {
        let repository = try makeRepository()
        let item = makeTodoItem(description: "Notes", category: .work, dueDate: DueDate(year: 2026, month: 10, day: 8))
        try await repository.add(item)
        #expect(try await repository.task(id: item.id) == item)
    }

    @Test func allTasksKeepsInsertionOrder() async throws {
        let repository = try makeRepository()
        let first = makeTodoItem(title: "First"), second = makeTodoItem(title: "Second")
        try await repository.add(first)
        try await repository.add(second)
        #expect(try await repository.allTasks() == [first, second])
    }

    @Test func addingDuplicateIDThrowsAndKeepsOneItem() async throws {
        let repository = try makeRepository()
        let item = makeTodoItem()
        try await repository.add(item)
        await #expect(throws: TodoItemRepositoryError.alreadyExists) { try await repository.add(item) }
        #expect(try await repository.allTasks() == [item])
    }

    @Test func updateReplacesTheStoredItemInPlace() async throws {
        let repository = try makeRepository()
        var first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        try await repository.add(first)
        try await repository.add(second)
        first.changeCategory(.shopping)
        first.complete(at: Date(timeIntervalSince1970: 9_000))
        try await repository.update(first)
        #expect(try await repository.allTasks() == [first, second])
    }

    @Test func updatingUnknownItemThrows() async throws {
        let repository = try makeRepository()
        await #expect(throws: TodoItemRepositoryError.notFound) { try await repository.update(makeTodoItem()) }
    }

    @Test func deleteRemovesOnlyThatItem() async throws {
        let repository = try makeRepository()
        let a = makeTodoItem(title: "A"), b = makeTodoItem(title: "B")
        try await repository.add(a)
        try await repository.add(b)
        try await repository.delete(id: a.id)
        #expect(try await repository.allTasks() == [b])
        #expect(try await repository.task(id: a.id) == nil)
    }

    @Test func deletingUnknownItemThrows() async throws {
        let repository = try makeRepository()
        await #expect(throws: TodoItemRepositoryError.notFound) { try await repository.delete(id: TodoItemID()) }
    }

    @Test func unknownIDReturnsNil() async throws {
        #expect(try await makeRepository().task(id: TodoItemID()) == nil)
    }

    @Test func aSecondRepositoryOnTheSameStoreSeesSavedItems() async throws {
        let container = try ModelContainer.inMemoryTodoItems()
        let item = makeTodoItem()
        try await makeRepository(container: container).add(item)
        #expect(try await makeRepository(container: container).allTasks() == [item])
    }
}
