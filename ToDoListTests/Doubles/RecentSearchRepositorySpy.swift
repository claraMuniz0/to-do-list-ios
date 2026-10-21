@testable import MyApp

final class RecentSearchRepositorySpy: RecentSearchRepository {
    var storedSearches: [SearchQuery] = []
    var errorToThrow: Error?
    private(set) var saveCallCount = 0

    func recentSearches() async throws -> [SearchQuery] {
        if let errorToThrow { throw errorToThrow }
        return storedSearches
    }

    func save(_ searches: [SearchQuery]) async throws {
        if let errorToThrow { throw errorToThrow }
        saveCallCount += 1
        storedSearches = searches
    }
}
