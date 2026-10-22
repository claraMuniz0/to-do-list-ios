import Foundation

enum SmartAddTextError: Error, Equatable {
    case empty
    case tooLong
}

/// The sentence a user types to describe a task, trimmed, non-blank and at most `maxLength` characters.
///
/// - Throws: `SmartAddTextError.empty` when blank; `.tooLong` when the trimmed text exceeds `maxLength`.
struct SmartAddText: Equatable {
    /// The Describe field stops input here, so `.tooLong` is a safety net, not a user-facing message.
    static let maxLength = 280

    let value: String

    /// Ignores length on purpose: an overlong sentence is not blank, the initializer rejects it with `.tooLong`.
    static func isBlank(_ rawValue: String) -> Bool {
        trimmed(rawValue).isEmpty
    }

    init(_ rawValue: String) throws {
        let trimmed = Self.trimmed(rawValue)
        guard !trimmed.isEmpty else { throw SmartAddTextError.empty }
        guard trimmed.count <= Self.maxLength else { throw SmartAddTextError.tooLong }
        value = trimmed
    }

    private static func trimmed(_ rawValue: String) -> String {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
