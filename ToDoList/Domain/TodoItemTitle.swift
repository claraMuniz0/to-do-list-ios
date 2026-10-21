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

    /// The single definition of "blank" (empty or only whitespace and newlines), shared by the initializer
    /// and by view models that must decide before building a title. It ignores length on purpose:
    /// an overlong title is not blank, it is rejected by the initializer with `.tooLong`.
    static func isBlank(_ rawValue: String) -> Bool {
        trimmed(rawValue).isEmpty
    }

    init(_ rawValue: String) throws {
        let trimmed = Self.trimmed(rawValue)
        guard !Self.isBlank(rawValue) else { throw TodoItemTitleError.empty }
        guard trimmed.count <= Self.maxLength else { throw TodoItemTitleError.tooLong }
        value = trimmed
    }

    private static func trimmed(_ rawValue: String) -> String {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
