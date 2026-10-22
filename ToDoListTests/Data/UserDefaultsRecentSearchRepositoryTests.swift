import Foundation
import Testing
@testable import MyApp

struct UserDefaultsRecentSearchRepositoryTests {
    /// Each test gets its own suite so nothing leaks between tests or into the app's real defaults.
    private func makeDefaults() -> (UserDefaults, String) {
        let name = "RecentSearchTests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    private func queries(_ texts: [String]) throws -> [SearchQuery] {
        try texts.map(SearchQuery.init)
    }

    @Test func startsEmpty() async throws {
        let (defaults, _) = makeDefaults()
        #expect(try await UserDefaultsRecentSearchRepository(defaults: defaults).recentSearches().isEmpty)
    }

    @Test func returnsSavedSearchesInOrder() async throws {
        let (defaults, _) = makeDefaults()
        let repository = UserDefaultsRecentSearchRepository(defaults: defaults)
        try await repository.save(queries(["b", "a"]))
        #expect(try await repository.recentSearches() == queries(["b", "a"]))
    }

    @Test func persistsAcrossRepositoryInstances() async throws {
        let (defaults, _) = makeDefaults()
        try await UserDefaultsRecentSearchRepository(defaults: defaults).save(queries(["a"]))
        #expect(try await UserDefaultsRecentSearchRepository(defaults: defaults).recentSearches() == queries(["a"]))
    }

    @Test func savingReplacesThePreviousList() async throws {
        let (defaults, _) = makeDefaults()
        let repository = UserDefaultsRecentSearchRepository(defaults: defaults)
        try await repository.save(queries(["a", "b"]))
        try await repository.save(queries(["c"]))
        #expect(try await repository.recentSearches() == queries(["c"]))
    }

    @Test func savingAnEmptyListClears() async throws {
        let (defaults, _) = makeDefaults()
        let repository = UserDefaultsRecentSearchRepository(defaults: defaults)
        try await repository.save(queries(["a"]))
        try await repository.save([])
        #expect(try await repository.recentSearches().isEmpty)
    }

    @Test func ignoresStoredValuesThatAreNotValidQueries() async throws {
        let (defaults, _) = makeDefaults()
        let key = UserDefaultsRecentSearchRepository.key
        defaults.set(["ok", "   ", String(repeating: "a", count: 121), "fine"], forKey: key)
        #expect(try await UserDefaultsRecentSearchRepository(defaults: defaults).recentSearches() == queries(["ok", "fine"]))
    }

    @Test func ignoresAStoredValueOfTheWrongType() async throws {
        let (defaults, _) = makeDefaults()
        defaults.set("not an array", forKey: UserDefaultsRecentSearchRepository.key)
        #expect(try await UserDefaultsRecentSearchRepository(defaults: defaults).recentSearches().isEmpty)
    }

    @Test func differentSuitesDoNotShareSearches() async throws {
        let (first, _) = makeDefaults()
        let (second, _) = makeDefaults()
        try await UserDefaultsRecentSearchRepository(defaults: first).save(queries(["a"]))
        #expect(try await UserDefaultsRecentSearchRepository(defaults: second).recentSearches().isEmpty)
    }
}
