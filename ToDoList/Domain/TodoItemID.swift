import Foundation

/// Identity generated in Domain so no database id ever leaks into the entity.
struct TodoItemID: Hashable {
    let uuid: UUID

    init(_ uuid: UUID = UUID()) {
        self.uuid = uuid
    }
}
