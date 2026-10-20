import Foundation

/// A task. Named `TodoItem`, not `Task`, so it never shadows Swift concurrency's `Task`.
///
/// State is `private(set)` and changes only through the named methods below.
/// Completion is a timestamp rather than a Bool so "finished N today" can be derived later.
struct TodoItem: Equatable {
    let id: TodoItemID
    let createdAt: Date
    private(set) var title: TodoItemTitle
    private(set) var description: String?
    private(set) var category: Category
    private(set) var dueDate: DueDate?
    private(set) var completedAt: Date?

    init(
        id: TodoItemID = TodoItemID(),
        title: TodoItemTitle,
        description: String? = nil,
        category: Category,
        dueDate: DueDate? = nil,
        createdAt: Date,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = Self.normalized(description)
        self.category = category
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool { completedAt != nil }

    /// Completing an already completed item is a no-op, keeping the first completion time.
    mutating func complete(at date: Date) {
        guard completedAt == nil else { return }
        completedAt = date
    }

    mutating func reopen() {
        completedAt = nil
    }

    mutating func rename(_ newTitle: TodoItemTitle) {
        title = newTitle
    }

    mutating func changeCategory(_ newCategory: Category) {
        category = newCategory
    }

    mutating func reschedule(_ newDueDate: DueDate?) {
        dueDate = newDueDate
    }

    /// Blank text clears the description (stored as `nil`).
    mutating func changeDescription(_ newDescription: String?) {
        description = Self.normalized(newDescription)
    }

    private static func normalized(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
