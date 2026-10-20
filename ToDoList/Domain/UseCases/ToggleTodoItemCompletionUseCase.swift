import Foundation

/// Completes an open item or reopens a completed one.
/// - Throws: `TodoItemRepositoryError.notFound` for an unknown id.
struct ToggleTodoItemCompletionUseCase {
    private let repository: TodoItemRepository
    private let dateProvider: DateProvider

    init(repository: TodoItemRepository, dateProvider: DateProvider) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    @discardableResult
    func execute(id: TodoItemID) async throws -> TodoItem {
        guard var item = try await repository.task(id: id) else { throw TodoItemRepositoryError.notFound }
        if item.isCompleted {
            item.reopen()
        } else {
            item.complete(at: dateProvider.now())
        }
        try await repository.update(item)
        return item
    }
}
