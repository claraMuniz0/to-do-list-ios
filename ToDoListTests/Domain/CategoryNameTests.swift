import Testing
@testable import MyApp

struct CategoryNameTests {
    @Test func rejectsBlankName() {
        #expect(throws: CategoryNameError.empty) { try CategoryName("  ") }
        #expect(throws: CategoryNameError.empty) { try CategoryName("") }
    }

    @Test func trimsName() throws {
        #expect(try CategoryName(" Health ").value == "Health")
    }
}
