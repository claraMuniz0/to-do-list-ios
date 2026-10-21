import Foundation
import Observation

/// `.loading` is the initial state so the Welcome screen never flashes for users who already have tasks.
enum TodoListViewState: Equatable {
    case loading
    case empty
    case loaded(TodoListSections)
    case error
}

/// How many open tasks a category has; completed tasks are not counted so the number matches the filtered list.
struct CategoryCount: Equatable {
    let category: Category
    let openCount: Int
}

@MainActor @Observable
final class TodoListViewModel {
    private(set) var state: TodoListViewState = .loading
    /// Set when the last toggle or quick add failed; the list stays visible, the view can show a message.
    private(set) var actionFailed = false
    /// The last deleted task, while the Undo toast is offered. The view runs the 5-second timer and calls `dismissUndo()`.
    private(set) var undoState: UndoState?
    /// Kept in memory only, so a relaunch starts on `.all`; survives reloads.
    private(set) var selectedFilter: TodoListFilter = .all

    private let getTodoItems: GetTodoItemsUseCase
    private let toggleCompletion: ToggleTodoItemCompletionUseCase
    private let addTodoItem: AddTodoItemUseCase
    private let restoreTodoItem: RestoreTodoItemUseCase
    private let deleteTodoItem: DeleteTodoItemUseCase

    init(
        getTodoItems: GetTodoItemsUseCase,
        toggleCompletion: ToggleTodoItemCompletionUseCase,
        addTodoItem: AddTodoItemUseCase,
        restoreTodoItem: RestoreTodoItemUseCase,
        deleteTodoItem: DeleteTodoItemUseCase
    ) {
        self.getTodoItems = getTodoItems
        self.toggleCompletion = toggleCompletion
        self.addTodoItem = addTodoItem
        self.restoreTodoItem = restoreTodoItem
        self.deleteTodoItem = deleteTodoItem
    }

    /// Counts every open task, not only those due today, whatever filter is selected.
    var subtitle: String {
        guard case .loaded(let sections) = state else { return "No tasks left" }
        guard !sections.todo.isEmpty else { return "All done" }
        let count = sections.todo.count
        return count == 1 ? "1 task left" : "\(count) tasks left"
    }

    var visibleSections: TodoListSections {
        guard case .loaded(let sections) = state else { return TodoListSections(items: []) }
        return selectedFilter.apply(to: sections)
    }

    var categoryCounts: [CategoryCount] {
        let open: [TodoItem]
        if case .loaded(let sections) = state { open = sections.todo } else { open = [] }
        return Category.defaults.map { category in
            CategoryCount(category: category, openCount: open.filter { $0.category == category }.count)
        }
    }

    var isCategoriesPanelOpen: Bool {
        if case .category = selectedFilter { return true }
        return false
    }

    /// Only for All and Active: Done and category filters show their own content or empty text.
    var isAllCaughtUp: Bool {
        guard case .loaded(let sections) = state, sections.todo.isEmpty else { return false }
        return selectedFilter == .all || selectedFilter == .active
    }

    /// Counts every task, not tasks "of today", because the data has no day-scoped notion of today's tasks.
    var allCaughtUpMessage: String {
        let total = totalTaskCount
        return "You finished \(total) of \(total) \(total == 1 ? "task" : "tasks"). Enjoy the break!"
    }

    var viewCompletedTitle: String { "View completed (\(completedTaskCount))" }

    /// Text for a filter that has nothing to show; nil while it has content, when All caught up applies, or before loading.
    var emptyFilterMessage: String? {
        guard case .loaded = state, !isAllCaughtUp else { return nil }
        let visible = visibleSections
        guard visible.todo.isEmpty && visible.completed.isEmpty else { return nil }
        switch selectedFilter {
        case .done: return "Nothing completed yet"
        case .category(let category): return "No open tasks in \(category.name.value)"
        case .all, .active: return nil
        }
    }

    func select(_ filter: TodoListFilter) {
        selectedFilter = filter
    }

    /// Opens the panel with Work preselected, or closes it back to All.
    func toggleCategories() {
        selectedFilter = isCategoriesPanelOpen ? .all : .category(.work)
    }

    /// Choosing the selected category again deselects it and falls back to All.
    func selectCategory(_ category: Category) {
        selectedFilter = selectedFilter == .category(category) ? .all : .category(category)
    }

    func viewCompleted() {
        select(.done)
    }

    /// Any thrown error ends in `.error`; previously loaded items are dropped rather than shown stale.
    func load() async {
        do {
            let items = try await getTodoItems.execute()
            state = items.isEmpty ? .empty : .loaded(TodoListSections(items: items))
        } catch {
            state = .error
        }
    }

    /// Goes back through `.loading` first so the error view disappears while the reload runs.
    func retry() async {
        state = .loading
        await load()
    }

    func toggle(id: TodoItemID) async {
        await perform { _ = try await toggleCompletion.execute(id: id) }
    }

    /// Returns whether a task was added. A blank title is ignored without flagging a failure.
    @discardableResult
    func quickAdd(title: String) async -> Bool {
        guard !TodoItemTitle.isBlank(title) else { return false }

        return await perform { _ = try await addTodoItem.quickAdd(title: title) }
    }

    /// Call after the Edit screen deleted `item`. A previous toast is replaced, which makes its delete final.
    func didDelete(_ item: TodoItem) async {
        undoState = UndoState(item: item)
        await load()
    }

    /// Swipe and VoiceOver delete: removes the task and offers Undo, like deleting from Edit. A failure sets `actionFailed`
    /// and leaves the previous toast alone.
    func delete(id: TodoItemID) async {
        await perform { undoState = UndoState(item: try await deleteTodoItem.execute(id: id)) }
    }

    /// Re-adds the deleted task with its original id and dates. A failure sets `actionFailed`; the toast closes either way.
    func undo() async {
        guard let item = undoState?.item else { return }
        undoState = nil
        await perform { try await restoreTodoItem.execute(item) }
    }

    func dismissUndo() {
        undoState = nil
    }

    private var totalTaskCount: Int {
        guard case .loaded(let sections) = state else { return 0 }
        return sections.todo.count + sections.completed.count
    }

    private var completedTaskCount: Int {
        guard case .loaded(let sections) = state else { return 0 }
        return sections.completed.count
    }

    /// Reloads after every action, success or not, so the list always mirrors the store.
    @discardableResult
    private func perform(_ action: () async throws -> Void) async -> Bool {
        do {
            try await action()
            actionFailed = false
        } catch {
            actionFailed = true
        }
        let succeeded = !actionFailed
        await load()
        return succeeded
    }
}
