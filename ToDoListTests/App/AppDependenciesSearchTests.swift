import Testing
@testable import MyApp

@MainActor
struct AppDependenciesSearchTests {
    @Test func theSearchUseCaseReadsFromTheSharedRepository() async throws {
        let dependencies = try AppDependencies.inMemory()
        let item = makeTodoItem(title: "Buy groceries")
        try await dependencies.todoItemRepository.add(item)

        let results = try await dependencies.makeSearchTodoItemsUseCase().execute(query: SearchQuery("gro"))

        #expect(results == [item])
    }

    @Test func theSearchViewModelSearchesTheSharedRepository() async throws {
        let dependencies = try AppDependencies.inMemory()
        let item = makeTodoItem(title: "Buy groceries")
        try await dependencies.todoItemRepository.add(item)
        let viewModel = dependencies.makeTodoSearchViewModel()

        await viewModel.setQuery("gro")

        #expect(viewModel.state == .results([item]))
    }

    @Test func theRecentSearchUseCasesShareTheInjectedRepository() async throws {
        var dependencies = try AppDependencies.inMemory()
        let spy = RecentSearchRepositorySpy()
        dependencies.recentSearchRepository = spy

        try await dependencies.makeRecordRecentSearchUseCase().execute(SearchQuery("groceries"))
        #expect(try await dependencies.makeGetRecentSearchesUseCase().execute() == [SearchQuery("groceries")])

        try await dependencies.makeClearRecentSearchesUseCase().execute()
        #expect(spy.storedSearches.isEmpty)
    }
}
