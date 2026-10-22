import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoSearchViewModelTests {
    private struct SUT {
        let viewModel: TodoSearchViewModel
        let tasks: TodoItemRepositorySpy
        let recents: RecentSearchRepositorySpy
    }

    private func makeSUT(
        items: [TodoItem] = [],
        recent: [SearchQuery] = [],
        sortOrder: TodoItemSortOrder = .default
    ) -> SUT {
        let tasks = TodoItemRepositorySpy()
        tasks.storedItems = items
        let recents = RecentSearchRepositorySpy()
        recents.storedSearches = recent
        let provider = DateProviderStub(current: Date(timeIntervalSince1970: 50_000))
        let viewModel = TodoSearchViewModel(
            searchTodoItems: SearchTodoItemsUseCase(repository: tasks),
            getRecentSearches: GetRecentSearchesUseCase(repository: recents),
            recordRecentSearch: RecordRecentSearchUseCase(repository: recents),
            clearRecentSearches: ClearRecentSearchesUseCase(repository: recents),
            toggleCompletion: ToggleTodoItemCompletionUseCase(repository: tasks, dateProvider: provider),
            sortOrder: sortOrder
        )
        return SUT(viewModel: viewModel, tasks: tasks, recents: recents)
    }

    // MARK: State and live filtering

    @Test func startsInTheRecentStateWithNoQueryAndNoScope() {
        let viewModel = makeSUT().viewModel
        #expect(viewModel.state == .recent)
        #expect(viewModel.query == "")
        #expect(viewModel.scope == nil)
    }

    @Test func loadShowsTheStoredRecentSearches() async throws {
        let recent = [try SearchQuery("groceries"), try SearchQuery("dentist")]
        let viewModel = makeSUT(recent: recent).viewModel
        await viewModel.load()
        #expect(viewModel.recentSearches == recent)
        #expect(viewModel.state == .recent)
    }

    @Test func typingShowsTheMatchingTasks() async {
        let match = makeTodoItem(title: "Buy groceries")
        let viewModel = makeSUT(items: [match, makeTodoItem(title: "Call mom")]).viewModel
        await viewModel.setQuery("gro")
        #expect(viewModel.query == "gro")
        #expect(viewModel.state == .results([match]))
    }

    @Test func matchingIgnoresCaseAndAccents() async {
        let match = makeTodoItem(title: "Café date")
        let viewModel = makeSUT(items: [match]).viewModel
        await viewModel.setQuery("CAFE")
        #expect(viewModel.state == .results([match]))
    }

    @Test func aBlankQueryReturnsToTheRecentState() async {
        let viewModel = makeSUT(items: [makeTodoItem(title: "Buy groceries")]).viewModel
        await viewModel.setQuery("gro")
        await viewModel.setQuery("   ")
        #expect(viewModel.state == .recent)
    }

    @Test func aQueryWithoutMatchesIsNoResultsCarryingTheTrimmedQuery() async throws {
        let viewModel = makeSUT(items: [makeTodoItem(title: "Buy groceries")]).viewModel
        await viewModel.setQuery("  gym ")
        #expect(viewModel.state == .noResults(try SearchQuery("gym")))
    }

    @Test func aQueryLongerThanTheLimitIsTruncatedToTheLimit() async throws {
        let viewModel = makeSUT().viewModel
        await viewModel.setQuery(String(repeating: "a", count: SearchQuery.maxLength + 30))
        #expect(viewModel.query.count == SearchQuery.maxLength)
        #expect(viewModel.state == .noResults(try SearchQuery(String(repeating: "a", count: SearchQuery.maxLength))))
    }

    @Test func resultsListOpenTasksBeforeCompletedOnesInTheSortOrder() async {
        let late = makeTodoItem(title: "Zed", createdAt: Date(timeIntervalSince1970: 10))
        let early = makeTodoItem(title: "Alpha", createdAt: Date(timeIntervalSince1970: 20))
        var done = makeTodoItem(title: "Done one")
        done.complete(at: Date(timeIntervalSince1970: 30))
        let viewModel = makeSUT(items: [done, late, early], sortOrder: .titleAZ).viewModel
        await viewModel.toggleScope(.personal)
        #expect(viewModel.state == .results([early, late, done]))
    }

    @Test func changingTheSortOrderRearrangesTheCurrentResults() async {
        let first = makeTodoItem(title: "Alpha", createdAt: Date(timeIntervalSince1970: 10))
        let second = makeTodoItem(title: "Beta", createdAt: Date(timeIntervalSince1970: 20))
        let viewModel = makeSUT(items: [first, second], sortOrder: .titleAZ).viewModel
        await viewModel.toggleScope(.personal)
        viewModel.setSortOrder(.newestFirst)
        #expect(viewModel.state == .results([second, first]))
    }

    @Test func resultCountTextIsSingularForOne() async {
        let viewModel = makeSUT(items: [makeTodoItem(title: "A"), makeTodoItem(title: "B")]).viewModel
        #expect(viewModel.resultCountText == nil)
        await viewModel.setQuery("a")
        #expect(viewModel.resultCountText == "1 result")
        await viewModel.setQuery("")
        await viewModel.toggleScope(.personal)
        #expect(viewModel.resultCountText == "2 results")
    }

    // MARK: Scope

    @Test func aScopeAloneShowsThatCategorysTasks() async {
        let work = makeTodoItem(title: "Report", category: .work)
        let viewModel = makeSUT(items: [work, makeTodoItem(title: "Milk", category: .shopping)]).viewModel
        await viewModel.toggleScope(.work)
        #expect(viewModel.scope == .work)
        #expect(viewModel.state == .results([work]))
    }

    @Test func tappingTheScopeAgainClearsIt() async {
        let viewModel = makeSUT(items: [makeTodoItem(category: .work)]).viewModel
        await viewModel.toggleScope(.work)
        await viewModel.toggleScope(.work)
        #expect(viewModel.scope == nil)
        #expect(viewModel.state == .recent)
    }

    @Test func tappingAnotherScopeReplacesIt() async {
        let viewModel = makeSUT().viewModel
        await viewModel.toggleScope(.work)
        await viewModel.toggleScope(.shopping)
        #expect(viewModel.scope == .shopping)
    }

    @Test func scopeAndQueryCombine() async {
        let match = makeTodoItem(title: "Plan report", category: .work)
        let items = [match, makeTodoItem(title: "Plan trip", category: .personal), makeTodoItem(title: "Other", category: .work)]
        let viewModel = makeSUT(items: items).viewModel
        await viewModel.toggleScope(.work)
        await viewModel.setQuery("plan")
        #expect(viewModel.state == .results([match]))
    }

    @Test func aScopeWithNoTasksIsNoResultsWithoutAQuery() async {
        let viewModel = makeSUT().viewModel
        await viewModel.toggleScope(.work)
        #expect(viewModel.state == .noResults(nil))
    }

    // MARK: Errors

    @Test func aSearchFailureEndsInTheErrorState() async {
        let sut = makeSUT()
        sut.tasks.errorToThrow = StubFailure()
        await sut.viewModel.setQuery("gro")
        #expect(sut.viewModel.state == .error)
    }
}
