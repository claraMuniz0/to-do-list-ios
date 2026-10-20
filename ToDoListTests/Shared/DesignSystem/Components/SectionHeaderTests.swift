import Testing
@testable import MyApp

struct SectionHeaderTests {
    @Test func labelIsUppercasedWithCount() {
        #expect(SectionHeader.label(title: "To do", count: 3) == "TO DO · 3")
        #expect(SectionHeader.label(title: "Completed", count: 1) == "COMPLETED · 1")
    }

    @Test func zeroCountIsStillShown() {
        #expect(SectionHeader.label(title: "To do", count: 0) == "TO DO · 0")
    }

    @Test func spokenLabelPluralizesAndAvoidsTheDot() {
        #expect(SectionHeader.accessibilityLabel(title: "To do", count: 3) == "To do, 3 tasks")
        #expect(SectionHeader.accessibilityLabel(title: "Completed", count: 1) == "Completed, 1 task")
        #expect(SectionHeader.accessibilityLabel(title: "To do", count: 0) == "To do, 0 tasks")
    }
}
