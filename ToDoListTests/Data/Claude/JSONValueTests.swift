import Foundation
import Testing
@testable import MyApp

struct JSONValueTests {
    @Test func roundTripsNestedValues() throws {
        let value = JSONValue.object([
            "title": .string("Buy milk"),
            "count": .number(2),
            "done": .bool(false),
            "tags": .array([.string("home"), .null]),
            "nested": .object(["flag": .bool(true)])
        ])

        let decoded = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))

        #expect(decoded == value)
    }

    @Test func decodesBooleansAsBooleansNotNumbers() throws {
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("true".utf8)) == .bool(true))
    }
}
