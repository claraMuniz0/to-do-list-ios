import Foundation

/// Converts between `TodoItem` and its stored record.
struct TodoItemMapper {
    private let categories: [Category]

    init(categories: [Category]) {
        self.categories = categories
    }

    func toRecord(_ item: TodoItem) -> TodoItemRecord {
        TodoItemRecord(
            id: item.id.uuid,
            title: item.title.value,
            details: item.description,
            categoryID: item.category.id.value,
            dueYear: item.dueDate?.year,
            dueMonth: item.dueDate?.month,
            dueDay: item.dueDate?.day,
            createdAt: item.createdAt,
            completedAt: item.completedAt,
            steps: item.steps.map { StepDTO(id: $0.id.uuid, title: $0.title.value, isDone: $0.isDone) }
        )
    }

    /// An unknown category id falls back to Personal so a removed category never hides a task.
    /// - Throws: `TodoItemTitleError.empty` when the stored title is blank, or `DueDateError.invalidDate` when the
    ///   stored due date does not exist (a corrupt record is an error, never silently a different day).
    func toDomain(_ record: TodoItemRecord) throws -> TodoItem {
        TodoItem(
            id: TodoItemID(record.id),
            title: try TodoItemTitle(record.title),
            description: record.details,
            category: categories.first { $0.id.value == record.categoryID } ?? .personal,
            dueDate: try dueDate(of: record),
            createdAt: record.createdAt,
            completedAt: record.completedAt,
            steps: record.steps.compactMap(step)
        )
    }

    /// A step whose stored title is no longer valid is dropped rather than failing the whole task.
    private func step(_ dto: StepDTO) -> Step? {
        guard let title = try? StepTitle(dto.title) else { return nil }
        return Step(id: StepID(dto.id), title: title, isDone: dto.isDone)
    }

    private func dueDate(of record: TodoItemRecord) throws -> DueDate? {
        guard let year = record.dueYear, let month = record.dueMonth, let day = record.dueDay else { return nil }
        return try DueDate(year: year, month: month, day: day)
    }
}
