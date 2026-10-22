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
    private(set) var steps: [Step]

    /// Keeps a task usable and stops Claude from flooding it.
    static var maxSteps: Int { StepList.maxSteps }

    init(
        id: TodoItemID = TodoItemID(),
        title: TodoItemTitle,
        description: String? = nil,
        category: Category,
        dueDate: DueDate? = nil,
        createdAt: Date,
        completedAt: Date? = nil,
        steps: [Step] = []
    ) {
        self.id = id
        self.title = title
        self.description = Self.normalized(description)
        self.category = category
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
        // Steps past the limit are dropped so the invariant holds even for stored data.
        self.steps = StepList(steps).steps
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

    /// `nil` when the task has no steps, so views never show an empty "0 of 0" bar.
    var stepsProgress: StepsProgress? { StepList(steps).progress }

    /// - Throws: `TodoItemError.tooManySteps` once the task already has `maxSteps`.
    @discardableResult
    mutating func addStep(_ title: StepTitle) throws -> StepID {
        try changeSteps { try $0.add(title) }
    }

    mutating func toggleStep(_ id: StepID) throws {
        try changeSteps { try $0.toggle(id) }
    }

    mutating func renameStep(_ id: StepID, to newTitle: StepTitle) throws {
        try changeSteps { try $0.rename(id, to: newTitle) }
    }

    mutating func removeStep(_ id: StepID) throws {
        try changeSteps { try $0.remove(id) }
    }

    /// `to` is the index the step ends up at, so moving the first of three steps to `2` puts it last.
    mutating func moveStep(from source: Int, to destination: Int) throws {
        try changeSteps { try $0.move(from: source, to: destination) }
    }

    /// Replaces every step at once, for a form that edited a `StepList` and saves it in one go.
    mutating func replaceSteps(_ newSteps: StepList) {
        steps = newSteps.steps
    }

    /// Applies a change to a copy and keeps it only if it succeeds, so a failed change never leaves a half-edited list.
    private mutating func changeSteps<Result>(_ change: (inout StepList) throws -> Result) throws -> Result {
        var list = StepList(steps)
        let result = try change(&list)
        steps = list.steps
        return result
    }

    private static func normalized(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
