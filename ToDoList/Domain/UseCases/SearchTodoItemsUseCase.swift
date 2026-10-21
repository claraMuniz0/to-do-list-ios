/// Finds tasks whose title or description contains the query, optionally limited to one category.
///
/// The query is optional (one entry point): `nil` with a category is the category-chip case, and
/// `nil` with no category returns every task. Completed tasks are included but listed after open ones.
/// No sort order is applied here; each part keeps the repository order and the caller sorts it.
/// Repository errors propagate unchanged.
struct SearchTodoItemsUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    func execute(query: SearchQuery?, category: Category? = nil) async throws -> [TodoItem] {
        let matches = try await repository.allTasks().filter { item in
            isInScope(item, category: category) && matches(item, query: query)
        }
        return matches.filter { !$0.isCompleted } + matches.filter { $0.isCompleted }
    }

    private func isInScope(_ item: TodoItem, category: Category?) -> Bool {
        category.map { item.category == $0 } ?? true
    }

    private func matches(_ item: TodoItem, query: SearchQuery?) -> Bool {
        guard let query else { return true }
        return query.matches(item.title.value) || (item.description.map(query.matches) ?? false)
    }
}
