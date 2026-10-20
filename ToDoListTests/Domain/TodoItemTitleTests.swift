import Testing
@testable import MyApp

struct TodoItemTitleTests {
    @Test func rejectsEmptyTitle() {
        #expect(throws: TodoItemTitleError.empty) {
            try TodoItemTitle("")
        }
    }

    @Test func rejectsWhitespaceOnlyTitle() {
        #expect(throws: TodoItemTitleError.empty) {
            try TodoItemTitle("  \n\t ")
        }
    }

    @Test func trimsSurroundingWhitespace() throws {
        let title = try TodoItemTitle("  Buy milk \n")
        #expect(title.value == "Buy milk")
    }

    @Test func keepsInnerWhitespace() throws {
        let title = try TodoItemTitle("Buy  oat milk")
        #expect(title.value == "Buy  oat milk")
    }

    @Test func equalTitlesAreEqual() throws {
        #expect(try TodoItemTitle(" A ") == TodoItemTitle("A"))
    }
}
