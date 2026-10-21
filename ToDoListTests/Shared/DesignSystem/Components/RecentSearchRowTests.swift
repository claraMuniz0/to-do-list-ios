import Testing
@testable import MyApp

struct RecentSearchRowTests {
    @Test func rowReadsAsARecentSearchWithTheTerm() {
        #expect(RecentSearchRowRules.rowAccessibilityLabel(term: "groceries") == "Recent search, groceries")
    }

    @Test func fillArrowIsAnActionNamedAfterTheTerm() {
        #expect(RecentSearchRowRules.fillAccessibilityLabel(term: "groceries") == "Use groceries")
    }

    @Test func rowIs52AndBothTargetsAreAtLeast44() {
        #expect(RecentSearchRowRules.height == 52)
        #expect(RecentSearchRowRules.minimumTapTarget >= 44)
    }
}
