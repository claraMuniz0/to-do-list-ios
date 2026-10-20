import Foundation

enum TodoItemTitleError: Error, Equatable {
    case empty
}

struct TodoItemTitle: Equatable {
    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TodoItemTitleError.empty }
        value = trimmed
    }
}
