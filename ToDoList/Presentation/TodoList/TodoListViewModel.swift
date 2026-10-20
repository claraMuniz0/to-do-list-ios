import Foundation
import Observation

/// `.loading` is the initial state so the Welcome screen never flashes for users who already have tasks.
enum TodoListViewState: Equatable {
    case loading
    case empty
    case loaded(TodoListSections)
    case error
}

@MainActor @Observable
final class TodoListViewModel {
    private(set) var state: TodoListViewState = .loading
    /// Set when the last toggle or quick add failed; the list stays visible, the view can show a message.
    private(set) var actionFailed = false

    private let getTodoItems: GetTodoItemsUseCase
    private let toggleCompletion: ToggleTodoItemCompletionUseCase
    private let addTodoItem: AddTodoItemUseCase

    init(
        getTodoItems: GetTodoItemsUseCase,
        toggleCompletion: ToggleTodoItemCompletionUseCase,
        addTodoItem: AddTodoItemUseCase
    ) {
        self.getTodoItems = getTodoItems
        self.toggleCompletion = toggleCompletion
        self.addTodoItem = addTodoItem
    }

    /// Counts every open task, not only those due today (the "today" meaning arrives with the filters).
    var subtitle: String {
        guard case .loaded(let sections) = state, !sections.todo.isEmpty else { return "No tasks left" }
        let count = sections.todo.count
        return count == 1 ? "1 task left" : "\(count) tasks left"
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
