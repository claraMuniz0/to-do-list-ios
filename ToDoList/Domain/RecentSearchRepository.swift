/// Stores the user's recent search terms, newest first.
///
/// Holds no rules: ordering, de-duplication and the size limit belong to the recent-search use cases.
/// Async and throwing so a different store can replace UserDefaults without changing Domain.
protocol RecentSearchRepository {
    func recentSearches() async throws -> [SearchQuery]
    /// Replaces the whole list; saving an empty list clears it.
    func save(_ searches: [SearchQuery]) async throws
}
