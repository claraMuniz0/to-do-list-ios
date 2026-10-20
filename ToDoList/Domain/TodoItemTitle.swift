import Foundation

enum TodoItemTitleError: Error, Equatable {
    case empty
    case tooLong
}

/// A non-blank task title of at most `maxLength` characters, trimmed of surrounding whitespace and newlines.
///
/// - Throws: `TodoItemTitleError.empty` when the input is empty or only whitespace;
///   `.tooLong` when the trimmed text exceeds `maxLength`. The form limits typing, so users never see this error.
struct TodoItemTitle: Equatable {
    /// The form cuts input at this length, so the `.tooLong` error is a safety net, not a user-facing message.
    static let maxLength = 120

    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TodoItemTitleError.empty }
        guard trimmed.count <= Self.maxLength else { throw TodoItemTitleError.tooLong }
        value = trimmed
    }
}
