import Foundation
@testable import MyApp

func makeTodoItem(
    id: TodoItemID = TodoItemID(),
    title: String = "Buy milk",
    description: String? = nil,
    category: Category = .personal,
    dueDate: DueDate? = nil,
    createdAt: Date = Date(timeIntervalSince1970: 1_000)
) -> TodoItem {
    TodoItem(
        id: id,
        title: try! TodoItemTitle(title),
        description: description,
        category: category,
        dueDate: dueDate,
        createdAt: createdAt
    )
}
