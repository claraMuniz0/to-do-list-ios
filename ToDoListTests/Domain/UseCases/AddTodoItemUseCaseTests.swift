import Foundation
import Testing
@testable import MyApp

struct AddTodoItemUseCaseTests {
    private let calendar = Calendar.utcGregorian
    private var now: Date { calendar.makeDate(2026, 10, 8) }

    private func makeUseCase(_ spy: TodoItemRepositorySpy) -> AddTodoItemUseCase {
        AddTodoItemUseCase(repository: spy, dateProvider: DateProviderStub(current: now), calendar: calendar)
    }

    @Test func storesAndReturnsTheNewItem() async throws {
        let spy = TodoItemRepositorySpy()
        let dueDate = makeDueDate(2026, 10, 9)

        let item = try await makeUseCase(spy).execute(
            title: "  Call the dentist ", description: "Friday", category: .work, dueDate: dueDate
        )

        #expect(item.title.value == "Call the dentist")
        #expect(item.description == "Friday")
        #expect(item.category == .work)
        #expect(item.dueDate == dueDate)
        #expect(item.createdAt == now)
        #expect(!item.isCompleted)
        #expect(spy.storedItems == [item])
    }

    @Test func dueDateAndDescriptionAreOptional() async throws {
        let item = try await makeUseCase(TodoItemRepositorySpy())
            .execute(title: "Buy milk", description: "  ", category: .personal, dueDate: nil)
        #expect(item.description == nil)
        #expect(item.dueDate == nil)
    }

    @Test func blankTitleIsRejectedBeforeTouchingTheRepository() async {
        let spy = TodoItemRepositorySpy()
        await #expect(throws: TodoItemTitleError.empty) {
            try await makeUseCase(spy).execute(title: "   ", description: nil, category: .personal, dueDate: nil)
        }
        #expect(spy.storedItems.isEmpty)
    }

    @Test func overlongTitleIsRejectedBeforeTouchingTheRepository() async {
        let spy = TodoItemRepositorySpy()
        let title = String(repeating: "a", count: TodoItemTitle.maxLength + 1)
        await #expect(throws: TodoItemTitleError.tooLong) {
            try await makeUseCase(spy).execute(title: title, description: nil, category: .personal, dueDate: nil)
        }
        #expect(spy.storedItems.isEmpty)
    }

    @Test func repositoryFailurePropagatesUnchanged() async {
        let spy = TodoItemRepositorySpy()
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists
        await #expect(throws: TodoItemRepositoryError.alreadyExists) {
            try await makeUseCase(spy).execute(title: "Buy milk", description: nil, category: .personal, dueDate: nil)
        }
    }

    @Test func quickAddUsesPersonalAndDueToday() async throws {
        let spy = TodoItemRepositorySpy()
        let item = try await makeUseCase(spy).quickAdd(title: "Pay rent")

        #expect(item.category == .personal)
        #expect(item.dueDate == makeDueDate(2026, 10, 8))
        #expect(item.description == nil)
        #expect(spy.storedItems == [item])
    }

    @Test func quickAddRejectsABlankTitle() async {
        let spy = TodoItemRepositorySpy()
        await #expect(throws: TodoItemTitleError.empty) { try await makeUseCase(spy).quickAdd(title: " ") }
        #expect(spy.storedItems.isEmpty)
    }
}
