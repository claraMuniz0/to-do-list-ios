import Foundation
import Testing
@testable import MyApp

struct TodoItemIDTests {
    @Test func generatedIDsAreUnique() {
        #expect(TodoItemID() != TodoItemID())
    }

    @Test func idsWrappingTheSameUUIDAreEqual() {
        let uuid = UUID()
        #expect(TodoItemID(uuid) == TodoItemID(uuid))
    }

    @Test func exposesTheWrappedUUID() {
        let uuid = UUID()
        #expect(TodoItemID(uuid).uuid == uuid)
    }
}
