import Foundation

/// Remembers the list's sort order between launches. Never fails: a missing or unreadable value means `TodoItemSortOrder.default`.
protocol SortOrderRepository {
    func sortOrder() -> TodoItemSortOrder
    func save(_ sortOrder: TodoItemSortOrder)
}
