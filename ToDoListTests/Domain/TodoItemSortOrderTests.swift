import Foundation
import Testing
@testable import MyApp

struct TodoItemSortOrderTests {
    private func item(_ title: String, due: DueDate? = nil, created: TimeInterval = 1_000) -> TodoItem {
        makeTodoItem(title: title, dueDate: due, createdAt: Date(timeIntervalSince1970: created))
    }

    private func completed(_ title: String, at time: TimeInterval) -> TodoItem {
        var item = makeTodoItem(title: title)
        item.complete(at: Date(timeIntervalSince1970: time))
        return item
    }

    private func titles(_ items: [TodoItem]) -> [String] { items.map(\.title.value) }

    @Test func dueDateIsTheDefault() {
        #expect(TodoItemSortOrder.default == .dueDate)
    }

    @Test func dueDateOrdersEarliestFirstAndUndatedLast() {
        let early = item("Early", due: makeDueDate(2026, 10, 1))
        let late = item("Late", due: makeDueDate(2026, 11, 1))
        let undated = item("Undated")
        #expect(titles(TodoItemSortOrder.dueDate.ordered([undated, late, early])) == ["Early", "Late", "Undated"])
    }

    @Test func dueDateTiesGoToTheOldestCreated() {
        let due = makeDueDate(2026, 10, 8)
        let older = item("Older", due: due, created: 1), newer = item("Newer", due: due, created: 2)
        #expect(titles(TodoItemSortOrder.dueDate.ordered([newer, older])) == ["Older", "Newer"])
    }

    @Test func newestFirstOrdersByCreatedDescending() {
        let old = item("Old", created: 1), mid = item("Mid", created: 2), new = item("New", created: 3)
        #expect(titles(TodoItemSortOrder.newestFirst.ordered([mid, old, new])) == ["New", "Mid", "Old"])
    }

    @Test func newestFirstTiesKeepInputOrder() {
        let a = item("A", created: 5), b = item("B", created: 5)
        #expect(titles(TodoItemSortOrder.newestFirst.ordered([a, b])) == ["A", "B"])
    }

    @Test func titleAZIgnoresCase() {
        let items = [item("banana"), item("Apple"), item("cherry")]
        #expect(titles(TodoItemSortOrder.titleAZ.ordered(items)) == ["Apple", "banana", "cherry"])
    }

    @Test func titleAZIgnoresDiacritics() {
        let items = [item("Zebra"), item("Éclair"), item("Eagle"), item("Apple")]
        #expect(titles(TodoItemSortOrder.titleAZ.ordered(items)) == ["Apple", "Eagle", "Éclair", "Zebra"])
    }

    @Test func titleAZTiesGoToTheOldestCreated() {
        let newer = item("cafe", created: 2), older = item("Café", created: 1)
        #expect(titles(TodoItemSortOrder.titleAZ.ordered([newer, older])) == ["Café", "cafe"])
    }

    @Test func arrangedPutsOrderedOpenItemsBeforeCompletedByMostRecentCompletion() {
        let b = item("B"), a = item("A")
        let first = completed("First", at: 5), last = completed("Last", at: 9)
        let result = TodoItemSortOrder.titleAZ.arranged([first, b, last, a])
        #expect(titles(result) == ["A", "B", "Last", "First"])
    }
}
