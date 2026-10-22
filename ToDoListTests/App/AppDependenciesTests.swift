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
            recentSearchRepository: RecentSearchRepositorySpy(),
            claudeClient: FakeClaudeClient(),
            claudeAvailability: ClaudeAvailability(apiKeyProvider: APIKeyProviderStub(key: nil))
        )
        let viewModel = dependencies.makeTodoListViewModel()
        #expect(viewModel.sortOrder == .titleAZ)

        viewModel.selectSortOrder(.newestFirst)

        #expect(spy.stored == .newestFirst)
    }
}

@MainActor
struct AppDependenciesClaudeTests {
    @Test func exposesTheInjectedClaudeClientAndAvailability() async throws {
        let fake = FakeClaudeClient(outcomes: [.success(ClaudeResponse(toolName: "t", toolInput: Data("{}".utf8)))])
        let dependencies = AppDependencies(
            todoItemRepository: InMemoryTodoItemRepository(),
            dateProvider: DateProviderStub(current: Date(timeIntervalSince1970: 50_000)),
            sortOrderRepository: SortOrderRepositorySpy(),
            recentSearchRepository: RecentSearchRepositorySpy(),
            claudeClient: fake,
            claudeAvailability: ClaudeAvailability(apiKeyProvider: APIKeyProviderStub(key: nil))
        )
        let request = ClaudeRequest(systemPrompt: "s", userMessage: "u", tool: ClaudeTool(name: "t", description: "d", inputSchema: .object([:])), maxTokens: 1)

        _ = try await dependencies.claudeClient.send(request)

        #expect(fake.receivedRequests == [request])
        #expect(!dependencies.claudeAvailability.isAvailable)
    }
}
