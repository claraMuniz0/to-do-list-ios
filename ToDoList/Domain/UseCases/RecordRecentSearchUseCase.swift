/// Puts a term at the top of the recent searches.
///
/// The caller decides when to record (only a query that had at least one result). A term that already exists
/// (ignoring case and accents) is moved to the top with its new spelling instead of duplicated, and the list
/// is cut to `maxCount`, dropping the oldest.
struct RecordRecentSearchUseCase {
    static let maxCount = 8

    private let repository: RecentSearchRepository

    init(repository: RecentSearchRepository) {
        self.repository = repository
    }

    func execute(_ query: SearchQuery) async throws {
        let others = try await repository.recentSearches().filter { !$0.isEquivalent(to: query) }
        try await repository.save(Array(([query] + others).prefix(Self.maxCount)))
    }
}
