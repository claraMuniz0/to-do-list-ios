import Foundation
import SwiftData

/// SwiftData storage shape for a `TodoItem`; never leaves the Data layer.
@Model
final class TodoItemRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String?
    var categoryID: String
    var dueYear: Int?
    var dueMonth: Int?
    var dueDay: Int?
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID,
        title: String,
        details: String?,
        categoryID: String,
        dueYear: Int?,
        dueMonth: Int?,
        dueDay: Int?,
        createdAt: Date,
        completedAt: Date?
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
    }
}
