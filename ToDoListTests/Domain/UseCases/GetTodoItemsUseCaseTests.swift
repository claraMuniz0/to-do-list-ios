import Testing
@testable import MyApp

struct GetTodoItemsUseCaseTests {
    @Test func returnsAnEmptyListWhenThereAreNoTasks() async throws {
        let useCase = GetTodoItemsUseCase(repository: TodoItemRepositorySpy())
        #expect(try await useCase.execute().isEmpty)
    }

    @Test func returnsTheRepositoryTasksInOrder() async throws {
        let spy = TodoItemRepositorySpy()
        let first = makeTodoItem(title: "First")
        let second = makeTodoItem(title: "Second")
        spy.storedItems = [first, second]
        let useCase = GetTodoItemsUseCase(repository: spy)

        #expect(try await useCase.execute() == [first, second])
        #expect(spy.allTasksCallCount == 1)
    }

    @Test func propagatesTheRepositoryErrorUnchanged() async {
        let spy = TodoItemRepositorySpy()
        spy.errorToThrow = TodoItemRepositoryError.notFound
        let useCase = GetTodoItemsUseCase(repository: spy)

        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await useCase.execute()
        }
    }
}
