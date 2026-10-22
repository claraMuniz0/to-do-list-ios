import Foundation
@testable import MyApp

final class SortOrderRepositorySpy: SortOrderRepository {
    var stored: TodoItemSortOrder
    private(set) var saveCallCount = 0

    init(stored: TodoItemSortOrder = .default) {
        self.stored = stored
    }

    func sortOrder() -> TodoItemSortOrder { stored }

    func save(_ sortOrder: TodoItemSortOrder) {
        saveCallCount += 1
        stored = sortOrder
    }
}
