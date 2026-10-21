import Foundation

enum TodoListFilter: Equatable {
    case all
    case active
    case done
    case category(Category)

    func apply(to sections: TodoListSections) -> TodoListSections {
        switch self {
        case .all: sections
        case .active: TodoListSections(items: sections.todo)
        case .done: TodoListSections(items: sections.completed)
        case .category(let category): TodoListSections(items: sections.todo.filter { $0.category == category })
        }
    }
}
