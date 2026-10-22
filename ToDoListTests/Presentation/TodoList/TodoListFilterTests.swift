import Foundation
import Testing
@testable import MyApp

struct TodoListFilterTests {
    private func completed(_ title: String, category: Category = .personal) -> TodoItem {
        var item = makeTodoItem(title: title, category: category)
        item.complete(at: Date(timeIntervalSince1970: 5))
        return item
    }

    private func sections(open: [TodoItem] = [], done: [TodoItem] = []) -> TodoListSections {
        TodoListSections(items: open + done)
    }

    private func titles(_ items: [TodoItem]) -> [String] { items.map(\.title.value) }

    @Test func allKeepsBothSections() {
        let result = TodoListFilter.all.apply(to: sections(open: [makeTodoItem(title: "A")], done: [completed("B")]))
        #expect(titles(result.todo) == ["A"])
        #expect(titles(result.completed) == ["B"])
    }

    @Test func activeKeepsOnlyOpenItems() {
        let result = TodoListFilter.active.apply(to: sections(open: [makeTodoItem(title: "A")], done: [completed("B")]))
        #expect(titles(result.todo) == ["A"])
        #expect(result.completed.isEmpty)
    }

    @Test func doneKeepsOnlyCompletedItems() {
        let result = TodoListFilter.done.apply(to: sections(open: [makeTodoItem(title: "A")], done: [completed("B")]))
        #expect(result.todo.isEmpty)
        #expect(titles(result.completed) == ["B"])
    }

    @Test func categoryKeepsOnlyOpenItemsOfThatCategory() {
        let source = sections(
            open: [makeTodoItem(title: "Work open", category: .work), makeTodoItem(title: "Home open", category: .personal)],
            done: [completed("Work done", category: .work)]
        )
        let result = TodoListFilter.category(.work).apply(to: source)
        #expect(titles(result.todo) == ["Work open"])
        #expect(result.completed.isEmpty)
    }

    @Test func categoryWithoutOpenItemsGivesEmptySections() {
        let result = TodoListFilter.category(.shopping).apply(to: sections(open: [makeTodoItem(category: .work)]))
        #expect(result.todo.isEmpty && result.completed.isEmpty)
    }

    @Test func emptyInputStaysEmptyForEveryFilter() {
        for filter in [TodoListFilter.all, .active, .done, .category(.work)] {
            let result = filter.apply(to: sections())
            #expect(result.todo.isEmpty && result.completed.isEmpty)
        }
    }

    @Test func filtersKeepTheSectionsSortOrder() {
        let old = makeTodoItem(title: "Old", createdAt: Date(timeIntervalSince1970: 1))
        let new = makeTodoItem(title: "New", createdAt: Date(timeIntervalSince1970: 2))
        let source = TodoListSections(items: [old, new], sortOrder: .newestFirst)
        for filter in [TodoListFilter.all, .active, .category(.personal)] {
            #expect(titles(filter.apply(to: source).todo) == ["New", "Old"])
        }
    }
}
