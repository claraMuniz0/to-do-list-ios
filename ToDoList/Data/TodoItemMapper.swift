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
            completedAt: item.completedAt
        )
    }

    /// An unknown category id falls back to Personal so a removed category never hides a task.
    /// - Throws: `TodoItemTitleError.empty` when the stored title is blank.
    func toDomain(_ record: TodoItemRecord) throws -> TodoItem {
        TodoItem(
            id: TodoItemID(record.id),
            title: try TodoItemTitle(record.title),
            description: record.details,
            category: categories.first { $0.id.value == record.categoryID } ?? .personal,
            dueDate: dueDate(of: record),
            createdAt: record.createdAt,
            completedAt: record.completedAt
        )
    }

    private func dueDate(of record: TodoItemRecord) -> DueDate? {
        guard let year = record.dueYear, let month = record.dueMonth, let day = record.dueDay else { return nil }
        return DueDate(year: year, month: month, day: day)
    }
}
