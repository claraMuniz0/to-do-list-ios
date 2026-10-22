import Testing
@testable import MyApp

struct SearchFieldTests {
    @Test func clearButtonShowsOnlyForNonEmptyText() {
        #expect(SearchFieldRules.showsClear(for: "") == false)
        #expect(SearchFieldRules.showsClear(for: "gro") == true)
    }

    @Test func whitespaceOnlyTextStillShowsClearSoTheUserCanEmptyTheField() {
        #expect(SearchFieldRules.showsClear(for: "  ") == true)
    }

    @Test func copyMatchesTheDesignAndAccessibilitySpec() {
        #expect(SearchFieldRules.placeholder == "Search tasks...")
        #expect(SearchFieldRules.accessibilityLabel == "Search tasks")
        #expect(SearchFieldRules.clearAccessibilityLabel == "Clear text")
        #expect(SearchFieldRules.cancelTitle == "Cancel")
    }

    @Test func fieldIs48ButtonsKeepA44TapTarget() {
        #expect(SearchFieldRules.height == 48)
        #expect(SearchFieldRules.minimumTapTarget >= 44)
    }
}
