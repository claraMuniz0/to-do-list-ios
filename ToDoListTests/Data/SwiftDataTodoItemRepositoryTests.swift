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
        let item = makeTodoItem(description: "Notes", category: .work, dueDate: makeDueDate(2026, 10, 8))
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

    @Test func allTasksReturnsOldestCreatedFirstRegardlessOfInsertionOrder() async throws {
        let repository = try makeRepository()
        let older = makeTodoItem(title: "Older", createdAt: Date(timeIntervalSince1970: 1))
        let newer = makeTodoItem(title: "Newer", createdAt: Date(timeIntervalSince1970: 2))
        try await repository.add(newer)
        try await repository.add(older)
        #expect(try await repository.allTasks() == [older, newer])
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

    // MARK: - steps

    private func steps(_ titles: String...) -> [Step] {
        titles.map { Step(title: try! StepTitle($0)) }
    }

    @Test func addThenFindKeepsSteps() async throws {
        let repository = try makeRepository()
        let item = makeTodoItem(steps: steps("A", "B"))
        try await repository.add(item)
        #expect(try await repository.task(id: item.id) == item)
    }

    @Test func updatePersistsStepChanges() async throws {
        let repository = try makeRepository()
        var item = makeTodoItem(steps: steps("A", "B", "C"))
        try await repository.add(item)

        try item.toggleStep(item.steps[0].id)
        try item.moveStep(from: 2, to: 0)
        try item.addStep(StepTitle("D"))
        try await repository.update(item)

        #expect(try await repository.task(id: item.id) == item)
    }

    @Test func updateCanRemoveEveryStep() async throws {
        let repository = try makeRepository()
        var item = makeTodoItem(steps: steps("A"))
        try await repository.add(item)
        try item.removeStep(item.steps[0].id)
        try await repository.update(item)
        #expect(try await repository.task(id: item.id)?.steps.isEmpty == true)
    }
}
