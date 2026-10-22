#if DEBUG
import Foundation

/// Preview-only wiring: builds `AppDependencies` from in-memory repositories so previews never touch SwiftData or UserDefaults.
enum PreviewDependencies {
    /// A task described with plain values, so previews do not build validated entities themselves.
    struct Task {
        var title: String
        var details: String?
        var category: Category
        var isCompleted = false
    }

    private struct FixedDateProvider: DateProvider {
        func now() -> Date { Date(timeIntervalSince1970: 1_791_460_800) } // 2026-10-08 12:00 UTC
    }

    private final class InMemorySortOrderRepository: SortOrderRepository {
        private var current: TodoItemSortOrder = .default
        func sortOrder() -> TodoItemSortOrder { current }
        func save(_ sortOrder: TodoItemSortOrder) { current = sortOrder }
    }

    private actor InMemoryRecentSearchRepository: RecentSearchRepository {
        private var searches: [SearchQuery]
        init(_ terms: [String]) { searches = terms.compactMap { try? SearchQuery($0) } }
        func recentSearches() async throws -> [SearchQuery] { searches }
        func save(_ searches: [SearchQuery]) async throws { self.searches = searches }
    }

    /// No tasks and no recent searches; for placeholders that are replaced before they are shown.
    static func empty() -> AppDependencies {
        build(repository: InMemoryTodoItemRepository(), recentSearches: [])
    }

    /// Seeds the tasks with fixed dates (completed ones finish after they were created), so every preview renders the same.
    static func make(tasks: [Task] = [], recentSearches: [String] = []) async -> AppDependencies {
        let repository = InMemoryTodoItemRepository()
        let base = Date(timeIntervalSince1970: 1_791_000_000)
        for (index, task) in tasks.enumerated() {
            guard let title = try? TodoItemTitle(task.title) else { continue }
            try? await repository.add(TodoItem(
                title: title, description: task.details, category: task.category,
                createdAt: base.addingTimeInterval(Double(index)),
                completedAt: task.isCompleted ? base.addingTimeInterval(Double(100 + index)) : nil
            ))
        }
        return build(repository: repository, recentSearches: recentSearches)
    }

    private static func build(repository: TodoItemRepository, recentSearches: [String]) -> AppDependencies {
        AppDependencies(
            todoItemRepository: repository,
            dateProvider: FixedDateProvider(),
            sortOrderRepository: InMemorySortOrderRepository(),
            recentSearchRepository: InMemoryRecentSearchRepository(recentSearches)
        )
    }
}
#endif
