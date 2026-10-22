import Foundation
import SwiftData

/// SwiftData storage shape for a `TodoItem`; never leaves the Data layer.
@Model
final class TodoItemRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Not `description`, which would clash with `CustomStringConvertible` on a class.
    var details: String?
    /// A plain id, not a relationship or a copy of the name and color, so Phase 7 only adds a category record.
    var categoryID: String
    /// The due date is three integers (all nil or all set), so a time-zone change never shifts the stored day.
    var dueYear: Int?
    var dueMonth: Int?
    var dueDay: Int?
    var createdAt: Date
    var completedAt: Date?
    /// Ordered, stored with the task. A defaulted property, so stores written before steps open unchanged.
    var steps: [StepDTO] = []

    init(
        id: UUID,
        title: String,
        details: String?,
        categoryID: String,
        dueYear: Int?,
        dueMonth: Int?,
        dueDay: Int?,
        createdAt: Date,
        completedAt: Date?,
        steps: [StepDTO] = []
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.categoryID = categoryID
        self.dueYear = dueYear
        self.dueMonth = dueMonth
        self.dueDay = dueDay
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.steps = steps
    }
}
