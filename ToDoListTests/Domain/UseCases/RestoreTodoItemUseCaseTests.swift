import Foundation
import Testing
@testable import MyApp

struct RestoreTodoItemUseCaseTests {
    @Test func readdsTheSameItemKeepingIdentityAndCompletion() async throws {
        let spy = TodoItemRepositorySpy()
        var item = makeTodoItem(description: "2 litres", createdAt: Date(timeIntervalSince1970: 7))
        item.complete(at: Date(timeIntervalSince1970: 9))

        try await RestoreTodoItemUseCase(repository: spy).execute(item)

        #expect(spy.storedItems == [item])
        #expect(spy.storedItems.first?.completedAt == Date(timeIntervalSince1970: 9))
    }

    @Test func restoringAnItemThatStillExistsThrowsAlreadyExists() async {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem()
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        await #expect(throws: TodoItemRepositoryError.alreadyExists) {
            try await RestoreTodoItemUseCase(repository: spy).execute(item)
        }
    }
}
