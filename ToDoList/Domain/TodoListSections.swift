import Foundation

/// The list's two sections, ordered as designed: open items by due date (undated last), then
/// oldest created; completed items by most recent completion.
struct TodoListSections: Equatable {
    let todo: [TodoItem]
    let completed: [TodoItem]

    init(items: [TodoItem]) {
        todo = Self.sorted(items.filter { !$0.isCompleted }, by: Self.opensBefore)
        completed = Self.sorted(items.filter(\.isCompleted)) { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private static func opensBefore(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?) where left != right: return left < right
        case (.some, nil): return true
        case (nil, .some): return false
        default: return lhs.createdAt < rhs.createdAt
        }
    }

    /// Ties keep input order explicitly, so the result never depends on sort stability.
    private static func sorted(_ items: [TodoItem], by areInIncreasingOrder: (TodoItem, TodoItem) -> Bool) -> [TodoItem] {
        items.enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
