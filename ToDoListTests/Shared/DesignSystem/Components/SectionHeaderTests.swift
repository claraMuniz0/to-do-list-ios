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
}
