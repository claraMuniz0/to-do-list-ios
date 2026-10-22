import Foundation
import SwiftData
import Testing
@testable import MyApp

/// The record shape shipped before steps existed: same entity name, no `steps` property.
private enum PreSteps {
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

        init(id: UUID, title: String, categoryID: String, createdAt: Date) {
            self.id = id
            self.title = title
            self.categoryID = categoryID
            self.createdAt = createdAt
        }
    }
}

@MainActor
struct TodoItemRecordMigrationTests {
    @Test func aStoreWrittenBeforeStepsStillOpensWithNoSteps() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "pre-steps-\(UUID().uuidString).store")
        defer { for suffix in ["", "-shm", "-wal"] { try? FileManager.default.removeItem(atPath: url.path + suffix) } }
        let id = UUID()

        do {
            let legacy = try ModelContainer(for: PreSteps.TodoItemRecord.self, configurations: ModelConfiguration(url: url))
            legacy.mainContext.insert(PreSteps.TodoItemRecord(id: id, title: "Old task", categoryID: "personal", createdAt: Date(timeIntervalSince1970: 1_000)))
            try legacy.mainContext.save()
        }

        let container = try ModelContainer(for: TodoItemRecord.self, configurations: ModelConfiguration(url: url))
        let item = try #require(try await SwiftDataTodoItemRepository(container: container).task(id: TodoItemID(id)))

        #expect(item.title.value == "Old task")
        #expect(item.steps.isEmpty)
    }
}
