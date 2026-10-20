import Testing
@testable import MyApp

struct CategoryTests {
    @Test func seedsWorkPersonalAndShoppingInOrder() {
        #expect(Category.defaults.map(\.name) == ["Work", "Personal", "Shopping"])
    }

    @Test func seededCategoriesHaveStableDistinctIDs() {
        #expect(Category.defaults.map(\.id) == ["work", "personal", "shopping"])
    }

    @Test func rejectsEmptyName() {
        #expect(throws: CategoryError.emptyName) {
            try Category(id: "health", name: "  ", colorKey: "green")
        }
    }

    @Test func trimsName() throws {
        let category = try Category(id: "health", name: " Health ", colorKey: "green")
        #expect(category.name == "Health")
    }

    @Test func sameValuesAreEqual() throws {
        let a = try Category(id: "health", name: "Health", colorKey: "green")
        let b = try Category(id: "health", name: "Health", colorKey: "green")
        #expect(a == b)
    }
}
