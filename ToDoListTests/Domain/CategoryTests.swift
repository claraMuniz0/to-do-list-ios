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
