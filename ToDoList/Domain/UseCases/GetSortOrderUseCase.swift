/// The remembered list sort order; never fails (see `SortOrderRepository`).
struct GetSortOrderUseCase {
    private let repository: SortOrderRepository

    init(repository: SortOrderRepository) {
        self.repository = repository
    }

    func execute() -> TodoItemSortOrder {
        repository.sortOrder()
    }
}
