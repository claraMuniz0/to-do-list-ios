import Testing
@testable import MyApp

struct GetTodoItemUseCaseTests {
    @Test func returnsTheItemWithThatID() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Buy milk")
        spy.storedItems = [makeTodoItem(title: "Other"), item]

        #expect(try await GetTodoItemUseCase(repository: spy).execute(id: item.id) == item)
    }

    @Test func unknownIDThrowsNotFound() async {
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await GetTodoItemUseCase(repository: TodoItemRepositorySpy()).execute(id: TodoItemID())
        }
    }

    @Test func repositoryFailurePropagatesUnchanged() async {
        let spy = TodoItemRepositorySpy()
        spy.errorToThrow = StubFailure()
        await #expect(throws: StubFailure()) {
            try await GetTodoItemUseCase(repository: spy).execute(id: TodoItemID())
        }
    }
}
