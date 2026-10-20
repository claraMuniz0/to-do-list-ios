import Foundation

enum CategoryNameError: Error, Equatable {
    case empty
}

/// A non-blank, trimmed category name.
///
/// - Throws: `CategoryNameError.empty` when blank.
struct CategoryName: Hashable {
    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryNameError.empty }
        value = trimmed
    }
}
