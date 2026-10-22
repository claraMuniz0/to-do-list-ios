import Foundation

/// Remembers the list's sort order between launches. Never fails: a missing or unreadable value means `TodoItemSortOrder.default`.
///
/// Deliberate decision: the order is a convenience preference, not user data, so a failure to read or write it is
/// silently absorbed (fall back to the default) instead of surfacing an error the user could do nothing about.
protocol SortOrderRepository {
    func sortOrder() -> TodoItemSortOrder
    func save(_ sortOrder: TodoItemSortOrder)
}
