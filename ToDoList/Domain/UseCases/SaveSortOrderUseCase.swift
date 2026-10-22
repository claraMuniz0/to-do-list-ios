/// Remembers the chosen list sort order for the next launch.
struct SaveSortOrderUseCase {
    private let repository: SortOrderRepository

    init(repository: SortOrderRepository) {
        self.repository = repository
    }

    func execute(_ sortOrder: TodoItemSortOrder) {
        repository.save(sortOrder)
    }
}
