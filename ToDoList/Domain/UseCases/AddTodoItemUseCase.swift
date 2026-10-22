import Foundation

/// Validates input and stamps `createdAt` before the repository is touched.
struct AddTodoItemUseCase {
    private let repository: TodoItemRepository
    private let dateProvider: DateProvider
    private let calendar: Calendar

    init(repository: TodoItemRepository, dateProvider: DateProvider, calendar: Calendar) {
        self.repository = repository
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    /// A blank description is stored as `nil`; a nil `dueDate` means the task has no due date; `steps` defaults to none; a task saved with every step done is stored completed.
    /// - Throws: `TodoItemTitleError` before the repository is touched, so an invalid title never leaves a partial write.
    @discardableResult
    func execute(
        title: String,
        description: String?,
        category: Category,
        dueDate: DueDate?,
        steps: StepList = StepList()
    ) async throws -> TodoItem {
        var item = TodoItem(
            title: try TodoItemTitle(title),
            description: description,
            category: category,
            dueDate: dueDate,
            createdAt: dateProvider.now(),
            steps: steps.steps
        )
        item.completeIfAllStepsDone(at: dateProvider.now())
        try await repository.add(item)
        return item
    }

    /// Quick add uses the same defaults as the form: Personal, due today.
    @discardableResult
    func quickAdd(title: String) async throws -> TodoItem {
        try await execute(
            title: title,
            description: nil,
            category: .personal,
            dueDate: .today(using: dateProvider, calendar: calendar)
        )
    }
}
