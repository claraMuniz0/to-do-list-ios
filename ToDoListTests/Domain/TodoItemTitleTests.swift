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

    @Test func rejectsUnicodeWhitespaceOnlyTitle() {
        #expect(throws: TodoItemTitleError.empty) {
            try TodoItemTitle("\u{00A0}\u{2003}")
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

    @Test func acceptsExactlyTheMaximumLength() throws {
        #expect(try TodoItemTitle(String(repeating: "a", count: TodoItemTitle.maxLength)).value.count == 120)
    }

    @Test func rejectsATitleOverTheMaximumLength() {
        #expect(throws: TodoItemTitleError.tooLong) {
            try TodoItemTitle(String(repeating: "a", count: TodoItemTitle.maxLength + 1))
        }
    }

    @Test func measuresLengthAfterTrimming() throws {
        let padded = "  " + String(repeating: "a", count: TodoItemTitle.maxLength) + "  "
        #expect(try TodoItemTitle(padded).value.count == TodoItemTitle.maxLength)
    }
}
