import Testing
@testable import MyApp

struct FilterPillTests {
    @Test func expandablePillSpeaksItsPanelState() {
        #expect(FilterPill.accessibilityValue(isExpanded: true) == "Expanded")
        #expect(FilterPill.accessibilityValue(isExpanded: false) == "Collapsed")
    }

    @Test func plainPillHasNoSpokenValue() {
        #expect(FilterPill.accessibilityValue(isExpanded: nil) == nil)
    }
}
