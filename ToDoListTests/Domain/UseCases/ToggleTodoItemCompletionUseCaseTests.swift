import Foundation
import Testing
@testable import MyApp

struct ToggleTodoItemCompletionUseCaseTests {
    private let now = Date(timeIntervalSince1970: 50_000)

    private func makeUseCase(_ spy: TodoItemRepositorySpy) -> ToggleTodoItemCompletionUseCase {
        ToggleTodoItemCompletionUseCase(repository: spy, dateProvider: DateProviderStub(current: now))
    }

    @Test func completesAnOpenItemAtTheCurrentTime() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem()
        spy.storedItems = [item]

        let updated = try await makeUseCase(spy).execute(id: item.id)

        #expect(updated.completedAt == now)
        #expect(spy.updatedItems == [updated])
    }

    @Test func reopensACompletedItem() async throws {
        let spy = TodoItemRepositorySpy()
        var item = makeTodoItem()
        item.complete(at: Date(timeIntervalSince1970: 1))
        spy.storedItems = [item]

        let updated = try await makeUseCase(spy).execute(id: item.id)

        #expect(!updated.isCompleted)
        #expect(spy.storedItems == [updated])
    }

    @Test func unknownIDThrowsNotFoundWithoutUpdating() async {
        let spy = TodoItemRepositorySpy()
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await makeUseCase(spy).execute(id: TodoItemID())
        }
        #expect(spy.updatedItems.isEmpty)
    }

    @Test func repositoryFailurePropagatesUnchanged() async {
        let spy = TodoItemRepositorySpy()
        spy.errorToThrow = TodoItemRepositoryError.notFound
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await makeUseCase(spy).execute(id: TodoItemID())
        }
    }
}
