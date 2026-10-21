import Foundation
import Testing
@testable import MyApp

struct TodoListSectionsTests {
    private func open(_ title: String, due: DueDate? = nil, created: TimeInterval = 1_000) -> TodoItem {
        makeTodoItem(title: title, dueDate: due, createdAt: Date(timeIntervalSince1970: created))
    }

    private func completed(_ title: String, at time: TimeInterval) -> TodoItem {
        var item = makeTodoItem(title: title)
        item.complete(at: Date(timeIntervalSince1970: time))
        return item
    }

    private func titles(_ items: [TodoItem]) -> [String] { items.map(\.title.value) }

    @Test func emptyInputGivesEmptySections() {
        let sections = TodoListSections(items: [])
        #expect(sections.todo.isEmpty && sections.completed.isEmpty)
    }

    @Test func splitsOpenFromCompleted() {
        let sections = TodoListSections(items: [open("A"), completed("B", at: 5)])
        #expect(titles(sections.todo) == ["A"])
        #expect(titles(sections.completed) == ["B"])
    }

    @Test func openItemsSortByDueDateAscending() {
        let early = open("Early", due: makeDueDate(2026, 10, 1))
        let late = open("Late", due: makeDueDate(2026, 11, 1))
        #expect(titles(TodoListSections(items: [late, early]).todo) == ["Early", "Late"])
    }

    @Test func itemsWithoutDueDateComeLast() {
        let dated = open("Dated", due: makeDueDate(2030, 1, 1))
        let undated = open("Undated", created: 1)
        #expect(titles(TodoListSections(items: [undated, dated]).todo) == ["Dated", "Undated"])
    }

    @Test func sameDueDateSortsByOldestCreatedFirst() {
        let due = makeDueDate(2026, 10, 8)
        let older = open("Older", due: due, created: 1), newer = open("Newer", due: due, created: 2)
        #expect(titles(TodoListSections(items: [newer, older]).todo) == ["Older", "Newer"])
    }

    @Test func fullyTiedItemsKeepInputOrder() {
        let a = open("A"), b = open("B"), c = open("C")
        #expect(titles(TodoListSections(items: [a, b, c]).todo) == ["A", "B", "C"])
    }

    @Test func completedSortByMostRecentlyCompletedFirst() {
        let sections = TodoListSections(items: [completed("Old", at: 1), completed("New", at: 9)])
        #expect(titles(sections.completed) == ["New", "Old"])
    }
}
