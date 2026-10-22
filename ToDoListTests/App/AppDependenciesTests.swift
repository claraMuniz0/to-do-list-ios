import Foundation
import Testing
@testable import MyApp

@MainActor
struct AppDependenciesTests {
    @Test func inMemoryWiresARepositoryThatStoresItems() async throws {
        let dependencies = try AppDependencies.inMemory()
        let item = makeTodoItem()
        try await dependencies.todoItemRepository.add(item)
        #expect(try await dependencies.todoItemRepository.allTasks() == [item])
    }

    @Test func eachInMemoryCompositionStartsWithAnEmptyRepository() async throws {
        let first = try AppDependencies.inMemory()
        try await first.todoItemRepository.add(makeTodoItem())
        #expect(try await AppDependencies.inMemory().todoItemRepository.allTasks().isEmpty)
    }
}

@MainActor
struct AppDependenciesViewModelTests {
    @Test func theTodoListViewModelStartsLoading() throws {
        #expect(try AppDependencies.inMemory().makeTodoListViewModel().state == .loading)
    }

    @Test func theTodoListViewModelReadsFromTheSharedRepository() async throws {
        let dependencies = try AppDependencies.inMemory()
        let item = makeTodoItem()
        try await dependencies.todoItemRepository.add(item)
        let viewModel = dependencies.makeTodoListViewModel()

        await viewModel.load()

        #expect(viewModel.state == .loaded(TodoListSections(items: [item])))
    }
}

@MainActor
struct AppDependenciesSortOrderTests {
    @Test func theTodoListViewModelUsesTheInjectedSortOrderRepository() {
        let spy = SortOrderRepositorySpy(stored: .titleAZ)
        let dependencies = AppDependencies(
            todoItemRepository: InMemoryTodoItemRepository(),
            dateProvider: DateProviderStub(current: Date(timeIntervalSince1970: 50_000)),
            sortOrderRepository: spy,
            recentSearchRepository: RecentSearchRepositorySpy()
        )
        let viewModel = dependencies.makeTodoListViewModel()
        #expect(viewModel.sortOrder == .titleAZ)

        viewModel.selectSortOrder(.newestFirst)

        #expect(spy.stored == .newestFirst)
    }
}
