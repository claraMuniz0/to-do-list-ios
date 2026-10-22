import Foundation

/// Identity generated in Domain so no database id ever leaks into the entity.
struct StepID: Hashable {
    let uuid: UUID

    init(_ uuid: UUID = UUID()) {
        self.uuid = uuid
    }
}
