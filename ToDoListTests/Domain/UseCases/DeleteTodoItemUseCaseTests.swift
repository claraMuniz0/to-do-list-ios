import Testing
@testable import MyApp

struct DeleteTodoItemUseCaseTests {
    @Test func deletesTheItemAndReturnsItForUndo() async throws {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem(title: "Buy milk", description: "2 litres")
        spy.storedItems = [item, makeTodoItem(title: "Other")]

        let deleted = try await DeleteTodoItemUseCase(repository: spy).execute(id: item.id)

        #expect(deleted == item)
        #expect(spy.deletedIDs == [item.id])
        #expect(spy.storedItems.count == 1)
    }

    @Test func unknownIDThrowsNotFoundWithoutDeleting() async {
        let spy = TodoItemRepositorySpy()
        spy.storedItems = [makeTodoItem()]

        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await DeleteTodoItemUseCase(repository: spy).execute(id: TodoItemID())
        }
        #expect(spy.deletedIDs.isEmpty)
        #expect(spy.storedItems.count == 1)
    }

    @Test func repositoryFailurePropagatesUnchanged() async {
        let spy = TodoItemRepositorySpy()
        let item = makeTodoItem()
        spy.storedItems = [item]
        spy.errorToThrow = TodoItemRepositoryError.alreadyExists

        await #expect(throws: TodoItemRepositoryError.alreadyExists) {
            try await DeleteTodoItemUseCase(repository: spy).execute(id: item.id)
        }
    }
}
