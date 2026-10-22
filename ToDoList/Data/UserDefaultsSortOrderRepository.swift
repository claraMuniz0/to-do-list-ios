import Foundation

/// Stores the sort order's raw value in UserDefaults.
///
/// Deliberate decision: a missing or unrecognised stored value (for example a case removed in a later version) silently
/// falls back to `TodoItemSortOrder.default`; it is never reported as an error.
struct UserDefaultsSortOrderRepository: SortOrderRepository {
    static let key = "todoList.sortOrder"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func sortOrder() -> TodoItemSortOrder {
        defaults.string(forKey: Self.key).flatMap(TodoItemSortOrder.init(rawValue:)) ?? .default
    }

    func save(_ sortOrder: TodoItemSortOrder) {
        defaults.set(sortOrder.rawValue, forKey: Self.key)
    }
}
