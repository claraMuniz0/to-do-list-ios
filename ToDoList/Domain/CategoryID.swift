import Foundation

enum CategoryIDError: Error, Equatable {
    case empty
}

/// Stable identity of a category; seeded ones use fixed ids (`work`, `personal`, `shopping`).
///
/// - Throws: `CategoryIDError.empty` when blank.
struct CategoryID: Hashable {
    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryIDError.empty }
        value = trimmed
    }
}
