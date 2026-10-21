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

    @Test func headerWithoutCountIsJustTheUppercasedTitle() {
        #expect(SectionHeader.label(title: "Categories", count: nil) == "CATEGORIES")
        #expect(SectionHeader.label(title: "Showing · Work", count: nil) == "SHOWING · WORK")
    }

    @Test func spokenLabelWithoutCountIsTheTitle() {
        #expect(SectionHeader.accessibilityLabel(title: "Showing · Work", count: nil) == "Showing, Work")
        #expect(SectionHeader.accessibilityLabel(title: "Categories", count: nil) == "Categories")
    }
}
