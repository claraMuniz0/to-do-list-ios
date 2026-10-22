import Foundation
import Observation

enum TodoSearchState: Equatable {
    case recent
    case results([TodoItem])
    /// The query is nil when only a category scope is active (no text typed).
    case noResults(SearchQuery?)
    case error
}

@MainActor @Observable
final class TodoSearchViewModel {
    private(set) var state: TodoSearchState = .recent
    /// The raw text of the field, cut to `SearchQuery.maxLength` characters; the matching trims it.
    private(set) var query = ""
    private(set) var scope: Category?
    private(set) var recentSearches: [SearchQuery] = []

    private var sortOrder: TodoItemSortOrder
    /// Bumped by every run so a slow, older search can never overwrite a newer one.
    private var runCounter = 0

    private let searchTodoItems: SearchTodoItemsUseCase
    private let getRecentSearches: GetRecentSearchesUseCase
    private let recordRecentSearch: RecordRecentSearchUseCase
    private let clearRecentSearches: ClearRecentSearchesUseCase
    private let toggleCompletion: ToggleTodoItemCompletionUseCase

    init(
        searchTodoItems: SearchTodoItemsUseCase,
        getRecentSearches: GetRecentSearchesUseCase,
        recordRecentSearch: RecordRecentSearchUseCase,
        clearRecentSearches: ClearRecentSearchesUseCase,
        toggleCompletion: ToggleTodoItemCompletionUseCase,
        sortOrder: TodoItemSortOrder = .default
    ) {
        self.searchTodoItems = searchTodoItems
        self.getRecentSearches = getRecentSearches
        self.recordRecentSearch = recordRecentSearch
        self.clearRecentSearches = clearRecentSearches
        self.toggleCompletion = toggleCompletion
        self.sortOrder = sortOrder
    }

    /// "1 result" / "N results" while results are shown; the view uppercases it for the header.
    var resultCountText: String? {
        guard case .results(let items) = state else { return nil }
        return items.count == 1 ? "1 result" : "\(items.count) results"
    }

    /// Loads the recent searches when search opens.
    func load() async {
        await refreshRecentSearches()
        await run()
    }

    /// Live filtering: called on every keystroke. Text beyond `SearchQuery.maxLength` is dropped, so "Add as task"
    /// always fits a title.
    func setQuery(_ text: String) async {
        query = String(text.prefix(SearchQuery.maxLength))
        await run()
    }

    /// Selecting the active category again clears the scope.
    func toggleScope(_ category: Category) async {
        scope = scope == category ? nil : category
        await run()
    }

    /// Applies a new list sort order to the results already shown, without reloading.
    func setSortOrder(_ order: TodoItemSortOrder) {
        sortOrder = order
        if case .results(let items) = state { state = .results(order.arranged(items)) }
    }

    private var parsedQuery: SearchQuery? { try? SearchQuery(query) }

    private func refreshRecentSearches() async {
        if let recents = try? await getRecentSearches.execute() { recentSearches = recents }
    }

    private func run() async {
        runCounter += 1
        let token = runCounter
        let parsed = parsedQuery
        guard parsed != nil || scope != nil else {
            state = .recent
            return
        }
        do {
            let found = try await searchTodoItems.execute(query: parsed, category: scope)
            guard token == runCounter else { return }
            state = found.isEmpty ? .noResults(parsed) : .results(sortOrder.arranged(found))
        } catch {
            guard token == runCounter else { return }
            state = .error
        }
    }
}
