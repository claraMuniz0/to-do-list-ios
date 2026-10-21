import Testing
@testable import MyApp

struct CategoryIDTests {
    @Test func rejectsBlankID() {
        #expect(throws: CategoryIDError.empty) { try CategoryID("  ") }
        #expect(throws: CategoryIDError.empty) { try CategoryID("") }
    }

    @Test func trimsID() throws {
        #expect(try CategoryID(" work ").value == "work")
    }
}
