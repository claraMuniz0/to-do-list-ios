import Testing
@testable import MyApp

struct TodoItemSortOrderTitleTests {
    @Test func eachOrderHasItsMenuTitle() {
        #expect(TodoItemSortOrder.dueDate.title == "Due date")
        #expect(TodoItemSortOrder.newestFirst.title == "Newest first")
        #expect(TodoItemSortOrder.titleAZ.title == "Title A to Z")
    }
}
