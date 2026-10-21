import Foundation
import Testing
@testable import MyApp

struct UpdateTodoItemUseCaseTests {
    private let dueDate = makeDueDate(2026, 10, 20)

    private func update(
        _ spy: TodoItemRepositorySpy,
        id: TodoItemID,
        title: String = "New title",
        description: String? = "New description",
        dueDate: DueDate? = makeDueDate(2026, 10, 20)
    ) async throws -> TodoItem {
        try await UpdateTodoItemUseCase(repository: spy).execute(
            id: id, title: title, description: description, category: .work, dueDate: dueDate
        )
    }

    @Test func appliesAllFieldsAndStoresTheItem() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Old", description: "Old description", category: .personal)
        spy.storedItems = [item]

        let updated = try await update(spy, id: item.id)

        #expect(updated.title.value == "New title")
        #expect(updated.description == "New description")
        #expect(updated.category == .work)
        #expect(updated.dueDate == dueDate)
        #expect(spy.storedItems == [updated])
    }

    @Test func keepsIdentityCreationAndCompletion() async throws {
        let spy = TodoItemRepositorySpy()
        var item = makeTodoItem(createdAt: Date(timeIntervalSince1970: 7))
        item.complete(at: Date(timeIntervalSince1970: 9))
        spy.storedItems = [item]

        let updated = try await update(spy, id: item.id)

        #expect(updated.id == item.id)
        #expect(updated.createdAt == item.createdAt)
        #expect(updated.completedAt == item.completedAt)
    }

    @Test func blankDescriptionClearsIt() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(description: "Something")
        spy.storedItems = [item]

        let updated = try await update(spy, id: item.id, description: "   ")

        #expect(updated.description == nil)
    }

    @Test func blankTitleThrowsBeforeTouchingTheRepository() async {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Old")
        spy.storedItems = [item]

        await #expect(throws: TodoItemTitleError.empty) {
            try await update(spy, id: item.id, title: "  ")
        }
        #expect(spy.updatedItems.isEmpty)
        #expect(spy.storedItems == [item])
    }

    @Test func unknownIDThrowsNotFound() async {
        let spy = TodoItemRepositorySpy()
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await update(spy, id: TodoItemID())
        }
        #expect(spy.updatedItems.isEmpty)
    }

    @Test func aNilDueDateClearsTheStoredOne() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(dueDate: makeDueDate(2026, 10, 1))
        spy.storedItems = [item]

        let updated = try await update(spy, id: item.id, dueDate: nil)

        #expect(updated.dueDate == nil)
    }

    @Test func aNilDescriptionClearsTheStoredOne() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(description: "Something")
        spy.storedItems = [item]

        #expect(try await update(spy, id: item.id, description: nil).description == nil)
    }

    @Test func aTooLongTitleThrowsBeforeTouchingTheRepository() async {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Old")
        spy.storedItems = [item]

        await #expect(throws: TodoItemTitleError.tooLong) {
            try await update(spy, id: item.id, title: String(repeating: "a", count: TodoItemTitle.maxLength + 1))
        }
        #expect(spy.storedItems == [item])
    }

    @Test func aFailureWhileUpdatingPropagatesAndKeepsTheStoredItem() async {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Old")
        spy.storedItems = [item]
        spy.updateError = StubFailure()

        await #expect(throws: StubFailure()) {
            try await update(spy, id: item.id)
        }
        #expect(spy.storedItems == [item])
    }
}
