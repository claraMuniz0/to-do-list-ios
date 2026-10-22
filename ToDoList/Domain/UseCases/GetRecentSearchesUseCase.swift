/// Recent searches, newest first. Repository errors propagate unchanged.
struct GetRecentSearchesUseCase {
    private let repository: RecentSearchRepository

    init(repository: RecentSearchRepository) {
        self.repository = repository
    }

    func execute() async throws -> [SearchQuery] {
        try await repository.recentSearches()
    }
}
