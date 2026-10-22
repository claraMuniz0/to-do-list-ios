import Foundation
import SwiftData

extension ModelContainer {
    /// Disk-backed store used by the app.
    static func todoItems() throws -> ModelContainer {
        try ModelContainer(for: TodoItemRecord.self)
    }

    /// Throwaway store for tests and previews.
    static func inMemoryTodoItems() throws -> ModelContainer {
        try ModelContainer(for: TodoItemRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}

/// Main-actor repository on the container's main context; fine for the MVP's small data set.
@MainActor
final class SwiftDataTodoItemRepository: TodoItemRepository {
    /// Held so the store outlives the repository: a `ModelContext` does not retain its container.
    private let container: ModelContainer
    private let context: ModelContext
    private let mapper: TodoItemMapper

    init(container: ModelContainer, categories: [Category] = Category.defaults) {
        self.container = container
        context = container.mainContext
        mapper = TodoItemMapper(categories: categories)
    }

    func add(_ item: TodoItem) throws {
        guard try record(for: item.id) == nil else { throw TodoItemRepositoryError.alreadyExists }
        context.insert(mapper.toRecord(item))
        try save()
    }

    /// Copies every mutable field but never `id` or `createdAt`, which are fixed at creation.
    /// - Throws: `TodoItemRepositoryError.notFound` for an unknown id.
    func update(_ item: TodoItem) throws {
        guard let stored = try record(for: item.id) else { throw TodoItemRepositoryError.notFound }
        let updated = mapper.toRecord(item)
        stored.title = updated.title
        stored.details = updated.details
        stored.categoryID = updated.categoryID
        stored.dueYear = updated.dueYear
        stored.dueMonth = updated.dueMonth
        stored.dueDay = updated.dueDay
        stored.completedAt = updated.completedAt
        stored.steps = updated.steps
        try save()
    }

    func delete(id: TodoItemID) throws {
        guard let stored = try record(for: id) else { throw TodoItemRepositoryError.notFound }
        context.delete(stored)
        try save()
    }

    func task(id: TodoItemID) throws -> TodoItem? {
        try record(for: id).map(mapper.toDomain)
    }

    /// Oldest created first; SwiftData gives no order guarantee without a sort.
    func allTasks() throws -> [TodoItem] {
        try context.fetch(FetchDescriptor<TodoItemRecord>(sortBy: [SortDescriptor(\.createdAt)])).map(mapper.toDomain)
    }

    private func record(for id: TodoItemID) throws -> TodoItemRecord? {
        let uuid = id.uuid
        var descriptor = FetchDescriptor<TodoItemRecord>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Rolls the context back on failure so a failed write never leaks into later reads.
    private func save() throws {
        do { try context.save() } catch {
            context.rollback()
            throw error
        }
    }
}
