import Foundation

enum StepTitleError: Error, Equatable {
    case empty
    case tooLong
}

/// A non-blank step title of at most `maxLength` characters, trimmed of surrounding whitespace and newlines.
///
/// - Throws: `StepTitleError.empty` when the input is empty or only whitespace;
///   `.tooLong` when the trimmed text exceeds `maxLength`.
struct StepTitle: Equatable {
    /// Same limit as `TodoItemTitle`; the field stops input here, so `.tooLong` is a safety net.
    static let maxLength = 120

    let value: String

    /// Ignores length on purpose: an overlong title is not blank, the initializer rejects it with `.tooLong`.
    static func isBlank(_ rawValue: String) -> Bool {
        trimmed(rawValue).isEmpty
    }

    init(_ rawValue: String) throws {
        let trimmed = Self.trimmed(rawValue)
        guard !trimmed.isEmpty else { throw StepTitleError.empty }
        guard trimmed.count <= Self.maxLength else { throw StepTitleError.tooLong }
        value = trimmed
    }

    private static func trimmed(_ rawValue: String) -> String {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
