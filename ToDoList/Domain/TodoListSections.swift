import Foundation

/// The list's two sections, ordered as designed: open items by the chosen sort order (default: due date, undated last,
/// then oldest created); completed items by most recent completion, whatever the sort order.
struct TodoListSections: Equatable {
    let todo: [TodoItem]
    let completed: [TodoItem]
    let sortOrder: TodoItemSortOrder

    init(items: [TodoItem], sortOrder: TodoItemSortOrder = .default) {
        self.sortOrder = sortOrder
        todo = sortOrder.ordered(items.filter { !$0.isCompleted })
        completed = TodoItemSortOrder.completedFirstByRecentCompletion(items.filter(\.isCompleted))
    }
}
