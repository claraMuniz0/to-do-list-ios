import Foundation

enum TodoItemTitleError: Error, Equatable {
    case empty
}

/// A non-blank task title, trimmed of surrounding whitespace and newlines.
///
/// - Throws: `TodoItemTitleError.empty` when the input is empty or only whitespace.
struct TodoItemTitle: Equatable {
    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TodoItemTitleError.empty }
        value = trimmed
    }
}
