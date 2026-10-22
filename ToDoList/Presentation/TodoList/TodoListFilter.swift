import Foundation

/// Selection of the list pills. Kept in memory only, so every launch starts on `.all`.
enum TodoListFilter: Equatable {
    case all
    case active
    case done
    case category(Category)

    /// `.category` keeps open tasks only, so the list under a category matches its open-task count. Results are re-sorted by `TodoListSections`.
    func apply(to sections: TodoListSections) -> TodoListSections {
        switch self {
        case .all: sections
        case .active: TodoListSections(items: sections.todo, sortOrder: sections.sortOrder)
        case .done: TodoListSections(items: sections.completed, sortOrder: sections.sortOrder)
        case .category(let category): TodoListSections(items: sections.todo.filter { $0.category == category }, sortOrder: sections.sortOrder)
        }
    }
}
