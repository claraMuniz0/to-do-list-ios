import Testing
@testable import MyApp

struct CategoryColorTests {
    @Test func trimsTheKey() {
        #expect(CategoryColor(" green ").key == "green")
    }

    @Test func sameKeysAreEqual() {
        #expect(CategoryColor("green") == CategoryColor("green"))
    }
}
