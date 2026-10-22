import Foundation

enum SearchQueryError: Error, Equatable {
    /// Blank text is not an error for the user: it means "no search", so the Recent state shows.
    case empty
    /// The screen cuts typed text to `SearchQuery.maxLength`, so only direct callers can hit this.
    case tooLong
}

/// A non-blank search text of at most `maxLength` characters, trimmed of surrounding whitespace and newlines.
///
/// - Throws: `SearchQueryError.empty` for empty or whitespace-only input (callers show the Recent state instead);
///   `.tooLong` when the trimmed text exceeds `maxLength`.
struct SearchQuery: Equatable {
    /// Same limit as `TodoItemTitle` so "Add as task" from a query always fits a title.
    static let maxLength = TodoItemTitle.maxLength

    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SearchQueryError.empty }
        guard trimmed.count <= Self.maxLength else { throw SearchQueryError.tooLong }
        value = trimmed
    }

    /// Case- and diacritic-insensitive substring match; the whole query is one substring, not separate words.
    func matches(_ text: String) -> Bool {
        Self.folded(text).contains(Self.folded(value))
    }

    /// True when both queries are the same term ignoring case and diacritics ("Café" and "cafe").
    func isEquivalent(to other: SearchQuery) -> Bool {
        Self.folded(value) == Self.folded(other.value)
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
