import Testing
@testable import MyApp

struct AppDependenciesTests {
    @Test func liveWiresAnInMemoryRepositoryThatStoresItems() async throws {
        let dependencies = AppDependencies.live()
        let item = makeTodoItem()
        try await dependencies.todoItemRepository.add(item)
        #expect(try await dependencies.todoItemRepository.allTasks() == [item])
    }

    @Test func eachLiveCompositionStartsWithAnEmptyRepository() async throws {
        let first = AppDependencies.live()
        try await first.todoItemRepository.add(makeTodoItem())
        #expect(try await AppDependencies.live().todoItemRepository.allTasks().isEmpty)
    }
}
