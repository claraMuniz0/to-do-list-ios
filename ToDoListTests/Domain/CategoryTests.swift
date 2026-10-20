import Testing
@testable import MyApp

struct CategoryTests {
    @Test func seedsWorkPersonalAndShoppingInOrder() {
        #expect(Category.defaults.map(\.name.value) == ["Work", "Personal", "Shopping"])
    }

    @Test func seededCategoriesHaveStableDistinctIDs() {
        #expect(Category.defaults.map(\.id.value) == ["work", "personal", "shopping"])
        #expect(Set(Category.defaults.map(\.id)).count == Category.defaults.count)
    }

    @Test func seededCategoriesUseTheirOwnIDAsColorKey() {
        #expect(Category.defaults.map(\.color.key) == ["work", "personal", "shopping"])
    }

    @Test func differentIDsWithTheSameNameAreNotEqual() throws {
        let name = try CategoryName("Health"), color = CategoryColor("green")
        #expect(Category(id: try CategoryID("a"), name: name, color: color)
            != Category(id: try CategoryID("b"), name: name, color: color))
    }

    @Test func sameValuesAreEqual() throws {
        func make() throws -> Category {
            Category(id: try CategoryID("health"), name: try CategoryName("Health"), color: CategoryColor("green"))
        }
        #expect(try make() == make())
    }
}

struct CategoryIDTests {
    @Test func rejectsBlankID() {
        #expect(throws: CategoryIDError.empty) { try CategoryID("  ") }
        #expect(throws: CategoryIDError.empty) { try CategoryID("") }
    }

    @Test func trimsID() throws {
        #expect(try CategoryID(" work ").value == "work")
    }
}

struct CategoryNameTests {
    @Test func rejectsBlankName() {
        #expect(throws: CategoryNameError.empty) { try CategoryName("  ") }
        #expect(throws: CategoryNameError.empty) { try CategoryName("") }
    }

    @Test func trimsName() throws {
        #expect(try CategoryName(" Health ").value == "Health")
    }
}

struct CategoryColorTests {
    @Test func trimsTheKey() {
        #expect(CategoryColor(" green ").key == "green")
    }

    @Test func sameKeysAreEqual() {
        #expect(CategoryColor("green") == CategoryColor("green"))
    }
}
