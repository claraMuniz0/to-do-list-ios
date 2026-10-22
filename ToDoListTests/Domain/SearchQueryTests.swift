import Testing
@testable import MyApp

struct SearchQueryTests {
    @Test func rejectsEmptyQuery() {
        #expect(throws: SearchQueryError.empty) { try SearchQuery("") }
    }

    @Test func rejectsWhitespaceOnlyQuery() {
        #expect(throws: SearchQueryError.empty) { try SearchQuery("  \n\t\u{00A0} ") }
    }

    @Test func trimsSurroundingWhitespace() throws {
        #expect(try SearchQuery("  gro \n").value == "gro")
    }

    @Test func keepsInnerWhitespace() throws {
        #expect(try SearchQuery("buy  milk").value == "buy  milk")
    }

    @Test func acceptsExactlyTheMaximumLength() throws {
        #expect(try SearchQuery(String(repeating: "a", count: 120)).value.count == 120)
    }

    @Test func rejectsAQueryOverTheMaximumLength() {
        #expect(throws: SearchQueryError.tooLong) { try SearchQuery(String(repeating: "a", count: 121)) }
    }

    @Test func measuresLengthAfterTrimming() throws {
        #expect(try SearchQuery("  " + String(repeating: "a", count: 120) + "  ").value.count == 120)
    }

    @Test func maximumLengthMatchesTheTitleSoAddAsTaskAlwaysFits() {
        #expect(SearchQuery.maxLength == TodoItemTitle.maxLength)
    }

    @Test func equalQueriesAreEqual() throws {
        #expect(try SearchQuery(" a ") == SearchQuery("a"))
    }

    // MARK: - matching

    @Test(arguments: ["Café", "CAFÉ", "cafe", "CAFE", "My café au lait"])
    func matchesIgnoringCaseAndAccents(text: String) throws {
        #expect(try SearchQuery("cafe").matches(text))
        #expect(try SearchQuery("CAFÉ").matches(text))
    }

    @Test func matchesASubstring() throws {
        #expect(try SearchQuery("gro").matches("Plan grocery budget"))
        #expect(try SearchQuery("gro").matches("Agro"))
    }

    @Test func doesNotMatchUnrelatedText() throws {
        #expect(try !SearchQuery("gym").matches("Buy groceries"))
    }

    @Test func treatsMultipleWordsAsOneSubstring() throws {
        #expect(try SearchQuery("buy milk").matches("Please buy milk now"))
        #expect(try !SearchQuery("buy milk").matches("milk to buy"))
    }

    @Test func equivalenceIgnoresCaseAndAccents() throws {
        #expect(try SearchQuery("Café").isEquivalent(to: SearchQuery("cafe")))
        #expect(try !SearchQuery("cafe").isEquivalent(to: SearchQuery("cafes")))
    }
}
