/// Removes every recent search immediately (no confirmation by design).
struct ClearRecentSearchesUseCase {
    private let repository: RecentSearchRepository

    init(repository: RecentSearchRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.save([])
    }
}
