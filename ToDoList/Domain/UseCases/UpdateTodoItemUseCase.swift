/// Applies edited fields through the entity's named methods, keeping id, `createdAt` and `completedAt`.
struct UpdateTodoItemUseCase {
    private let repository: TodoItemRepository

    init(repository: TodoItemRepository) {
        self.repository = repository
    }

    /// A blank description clears it; a nil `dueDate` removes the due date; nil `steps` leaves the steps as stored.
    /// - Throws: `TodoItemTitleError` before the repository is touched; `TodoItemRepositoryError.notFound` for an unknown id.
    @discardableResult
    func execute(
        id: TodoItemID,
        title: String,
        description: String?,
        category: Category,
        dueDate: DueDate?,
        steps: StepList? = nil
    ) async throws -> TodoItem {
        let newTitle = try TodoItemTitle(title)
        guard var item = try await repository.task(id: id) else { throw TodoItemRepositoryError.notFound }
        item.rename(newTitle)
        item.changeDescription(description)
        item.changeCategory(category)
        item.reschedule(dueDate)
        if let steps { item.replaceSteps(steps) }
        try await repository.update(item)
        return item
    }
}
