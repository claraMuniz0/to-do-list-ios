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

    @discardableResult
    func execute(title: String, description: String?, category: Category, dueDate: DueDate?) async throws -> TodoItem {
        let item = TodoItem(
            title: try TodoItemTitle(title),
            description: description,
            category: category,
            dueDate: dueDate,
            createdAt: dateProvider.now()
        )
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
