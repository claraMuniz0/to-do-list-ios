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
    /// Text for VoiceOver. Set on submit, when the scope changes, when a toggle or form outcome changes the result
    /// count, and after clearing recents; never per keystroke.
    private(set) var announcement: SearchAnnouncement?

    /// Called with the deleted task when the Edit form reports `.deleted`, so the list can show its Undo toast.
    var onDeleted: ((TodoItem) -> Void)?

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

    /// Toggles a result's completion and refreshes. A failure sets `actionFailed`; the results are refreshed either way.
    func toggle(id: TodoItemID) async {
        let wasCompleted = shownItem(id: id)?.isCompleted
        do {
            _ = try await toggleCompletion.execute(id: id)
            actionFailed = false
            if let wasCompleted { announce(wasCompleted ? "Marked not done" : "Marked done") }
        } catch {
            actionFailed = true
        }
        await refresh()
    }

    private func shownItem(id: TodoItemID) -> TodoItem? {
        guard case .results(let items) = state else { return nil }
        return items.first { $0.id == id }
    }

    /// Call when the Add or Edit form closes over search. `.saved` re-runs the query; `.deleted` hands the item to
    /// `onDeleted` (the list's Undo toast) and refreshes; `.cancelled` does nothing.
    func didFinishForm(_ outcome: TodoItemFormOutcome) async {
        switch outcome {
        case .saved:
            await refresh()
        case .deleted(let item):
            onDeleted?(item)
            await refresh()
        case .cancelled:
            break
        }
    }

    /// The prefill for the Add form: the trimmed query. Only in `.noResults` with typed text (not for a scope alone).
    var addAsTaskTitle: String? {
        guard case .noResults(let query?) = state else { return nil }
        return query.value
    }

    /// The category the Add form starts with: the active scope, or nil for the form's default.
    var addAsTaskCategory: Category? { scope }

    func clearAllRecentSearches() async {
        do {
            try await clearRecentSearches.execute()
            actionFailed = false
            announce("Recent searches cleared")
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

    /// `nil` for blank text. `try?` also swallows `.tooLong`, but that cannot happen: `query` is already cut to
    /// `SearchQuery.maxLength` characters, so the trimmed text never exceeds the limit.
    private var parsedQuery: SearchQuery? { try? SearchQuery(query) }

    private func refreshRecentSearches() async {
        do {
            recentSearches = try await getRecentSearches.execute()
        } catch {
            actionFailed = true
        }
    }

    /// Only a typed query that has results is worth remembering; a scope alone or an empty search is not.
    /// Re-runs after a mutation; announces only if the number of results changed.
    private func refresh() async {
        let before = shownCount
        await run()
        if shownCount != before { announceState() }
    }

    private var shownCount: Int {
        if case .results(let items) = state { return items.count }
        return 0
    }

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
        announce(text)
    }

    private func announce(_ text: String) {
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
