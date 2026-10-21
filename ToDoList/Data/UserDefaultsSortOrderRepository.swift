import Foundation

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
