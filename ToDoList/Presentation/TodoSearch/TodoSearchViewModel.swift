import Foundation
import Observation

enum TodoSearchState: Equatable {
    case recent
    case results([TodoItem])
    /// The query is nil when only a category scope is active (no text typed).
    case noResults(SearchQuery?)
    case error
}

/// `sequence` makes two identical messages distinct, so the view's change observer fires on a repeated submit.
struct SearchAnnouncement: Equatable {
    let text: String
    let sequence: Int
}

@MainActor @Observable
final class TodoSearchViewModel {
    private(set) var state: TodoSearchState = .recent
    /// The raw text of the field, cut to `SearchQuery.maxLength` characters; the matching trims it.
    private(set) var query = ""
    private(set) var scope: Category?
    private(set) var recentSearches: [SearchQuery] = []
    /// Set when the last record or clear of recent searches failed; results stay visible.
    private(set) var actionFailed = false
    /// Text for VoiceOver. Set only on submit or when the scope changes, never per keystroke.
    private(set) var announcement: SearchAnnouncement?

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
        announceState()
    }

    /// Keyboard "search" key: records the query (if it found something) and announces the outcome.
    func submit() async {
        await run()
        await recordIfFound()
        announceState()
    }

    /// Call when a result row is tapped; the result itself is handled by the view (Edit or toggle).
    func didSelectResult() async {
        await recordIfFound()
    }

    /// Tapping a recent row: fills the query, runs it and records it again so it moves to the top.
    func selectRecent(_ term: SearchQuery) async {
        query = term.value
        await submit()
    }

    /// The arrow on a recent row: fills the query only, so the user can keep editing it. Results update live.
    func fill(_ term: SearchQuery) async {
        await setQuery(term.value)
    }

    func clearAllRecentSearches() async {
        do {
            try await clearRecentSearches.execute()
            actionFailed = false
        } catch {
            actionFailed = true
        }
        await refreshRecentSearches()
    }

    /// Applies a new list sort order to the results already shown, without reloading.
    func setSortOrder(_ order: TodoItemSortOrder) {
        sortOrder = order
        if case .results(let items) = state { state = .results(order.arranged(items)) }
    }

    private var parsedQuery: SearchQuery? { try? SearchQuery(query) }

    private func refreshRecentSearches() async {
        do {
            recentSearches = try await getRecentSearches.execute()
        } catch {
            actionFailed = true
        }
    }

    /// Only a typed query that has results is worth remembering; a scope alone or an empty search is not.
    private func recordIfFound() async {
        guard case .results = state, let parsed = parsedQuery else { return }
        do {
            try await recordRecentSearch.execute(parsed)
            actionFailed = false
        } catch {
            actionFailed = true
        }
        await refreshRecentSearches()
    }

    private func announceState() {
        let text: String
        switch state {
        case .results: text = resultCountText ?? ""
        case .noResults: text = "No tasks found"
        case .recent, .error: return
        }
        announcement = SearchAnnouncement(text: text, sequence: (announcement?.sequence ?? 0) + 1)
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
