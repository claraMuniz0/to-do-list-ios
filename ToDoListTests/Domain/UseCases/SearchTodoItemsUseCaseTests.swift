import Foundation
import Testing
@testable import MyApp

struct SearchTodoItemsUseCaseTests {
    private func makeUseCase(_ items: [TodoItem]) -> (SearchTodoItemsUseCase, TodoItemRepositorySpy) {
        let spy = TodoItemRepositorySpy()
        spy.storedItems = items
        return (SearchTodoItemsUseCase(repository: spy), spy)
    }

    private func complete(_ item: TodoItem) -> TodoItem {
        var done = item
        done.complete(at: Date(timeIntervalSince1970: 5_000))
        return done
    }

    @Test func matchesOnTitle() async throws {
        let match = makeTodoItem(title: "Buy groceries")
        let (useCase, _) = makeUseCase([match, makeTodoItem(title: "Call dentist")])
        #expect(try await useCase.execute(query: SearchQuery("gro")) == [match])
    }

    @Test func matchesOnDescription() async throws {
        let match = makeTodoItem(title: "Errands", description: "Pick up groceries")
        let (useCase, _) = makeUseCase([match, makeTodoItem(title: "Call dentist")])
        #expect(try await useCase.execute(query: SearchQuery("GRO")) == [match])
    }

    @Test func ignoresCaseAndAccents() async throws {
        let match = makeTodoItem(title: "Meet at the Café")
        let (useCase, _) = makeUseCase([match])
        #expect(try await useCase.execute(query: SearchQuery("cafe")) == [match])
    }

    @Test func doesNotSearchTheCategoryName() async throws {
        let (useCase, _) = makeUseCase([makeTodoItem(title: "Report", category: .shopping)])
        #expect(try await useCase.execute(query: SearchQuery("shopping")).isEmpty)
    }

    @Test func returnsNothingWhenNothingMatches() async throws {
        let (useCase, _) = makeUseCase([makeTodoItem(title: "Buy milk")])
        #expect(try await useCase.execute(query: SearchQuery("gym")).isEmpty)
    }

    @Test func includesCompletedTasksAfterOpenOnes() async throws {
        let doneFirst = complete(makeTodoItem(title: "Groceries done"))
        let open = makeTodoItem(title: "Groceries open")
        let (useCase, _) = makeUseCase([doneFirst, open])
        #expect(try await useCase.execute(query: SearchQuery("gro")) == [open, doneFirst])
    }

    @Test func keepsRepositoryOrderWithinOpenAndCompletedParts() async throws {
        let open1 = makeTodoItem(title: "gro 1")
        let done1 = complete(makeTodoItem(title: "gro 2"))
        let open2 = makeTodoItem(title: "gro 3")
        let done2 = complete(makeTodoItem(title: "gro 4"))
        let (useCase, _) = makeUseCase([done1, open1, done2, open2])
        #expect(try await useCase.execute(query: SearchQuery("gro")) == [open1, open2, done1, done2])
    }

    @Test func scopesToACategoryTogetherWithTheQuery() async throws {
        let work = makeTodoItem(title: "Report groceries", category: .work)
        let shopping = makeTodoItem(title: "Buy groceries", category: .shopping)
        let (useCase, _) = makeUseCase([work, shopping])
        #expect(try await useCase.execute(query: SearchQuery("gro"), category: .shopping) == [shopping])
    }

    @Test func aCategoryWithoutQueryReturnsEveryTaskOfThatCategory() async throws {
        let work = makeTodoItem(title: "Report", category: .work)
        let doneWork = complete(makeTodoItem(title: "Old", category: .work))
        let shopping = makeTodoItem(title: "Milk", category: .shopping)
        let (useCase, _) = makeUseCase([doneWork, shopping, work])
        #expect(try await useCase.execute(query: nil, category: .work) == [work, doneWork])
    }

    @Test func noQueryAndNoCategoryReturnsEverythingOpenFirst() async throws {
        let done = complete(makeTodoItem(title: "A"))
        let open = makeTodoItem(title: "B")
        let (useCase, _) = makeUseCase([done, open])
        #expect(try await useCase.execute(query: nil) == [open, done])
    }

    @Test func loadsTasksOnce() async throws {
        let (useCase, spy) = makeUseCase([])
        _ = try await useCase.execute(query: SearchQuery("a"))
        #expect(spy.allTasksCallCount == 1)
    }

    @Test func propagatesTheRepositoryErrorUnchanged() async throws {
        let (useCase, spy) = makeUseCase([])
        spy.errorToThrow = TodoItemRepositoryError.notFound
        let query = try SearchQuery("a")
        await #expect(throws: TodoItemRepositoryError.notFound) {
            try await useCase.execute(query: query)
        }
    }
}
