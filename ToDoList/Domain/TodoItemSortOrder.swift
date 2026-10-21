import Foundation

/// How the open tasks are ordered. Completed tasks ignore it and stay most recently completed first.
enum TodoItemSortOrder: String, CaseIterable, Equatable {
    case dueDate
    case newestFirst
    case titleAZ

    static let `default`: TodoItemSortOrder = .dueDate

    /// Orders open tasks. Remaining ties fall back to input order, so the result never depends on sort stability.
    func ordered(_ items: [TodoItem]) -> [TodoItem] {
        Self.stable(items, by: precedes)
    }

    /// Open tasks in this order, then completed tasks by most recent completion. Reused by the list and by search results.
    func arranged(_ items: [TodoItem]) -> [TodoItem] {
        ordered(items.filter { !$0.isCompleted }) + Self.completedFirstByRecentCompletion(items.filter(\.isCompleted))
    }

    static func completedFirstByRecentCompletion(_ items: [TodoItem]) -> [TodoItem] {
        stable(items) { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func precedes(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch self {
        case .dueDate:
            switch (lhs.dueDate, rhs.dueDate) {
            case let (left?, right?) where left != right: return left < right
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.createdAt < rhs.createdAt
            }
        case .newestFirst:
            return lhs.createdAt > rhs.createdAt
        case .titleAZ:
            let result = lhs.title.value.compare(rhs.title.value, options: [.caseInsensitive, .diacriticInsensitive])
            return result == .orderedSame ? lhs.createdAt < rhs.createdAt : result == .orderedAscending
        }
    }

    private static func stable(_ items: [TodoItem], by areInIncreasingOrder: (TodoItem, TodoItem) -> Bool) -> [TodoItem] {
        items.enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
