import Foundation
import Testing
@testable import MyApp

struct StepIDTests {
    @Test func generatedIDsAreUnique() {
        #expect(StepID() != StepID())
    }

    @Test func idsWrappingTheSameUUIDAreEqual() {
        let uuid = UUID()
        #expect(StepID(uuid) == StepID(uuid))
    }

    @Test func exposesTheWrappedUUID() {
        let uuid = UUID()
        #expect(StepID(uuid).uuid == uuid)
    }
}
