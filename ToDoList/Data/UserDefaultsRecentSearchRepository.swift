import Foundation

/// Keeps recent searches as a plain array of strings in UserDefaults (not relational data, so no SwiftData model).
///
/// Stored values that are no longer valid queries (blank or overlong, e.g. after the limit changed) are skipped
/// on read rather than failing the whole list.
struct UserDefaultsRecentSearchRepository: RecentSearchRepository {
    static let key = "recentSearches"

    // UserDefaults is documented as thread-safe; the type is not yet marked Sendable.
    nonisolated(unsafe) private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recentSearches() async throws -> [SearchQuery] {
        let stored = defaults.stringArray(forKey: Self.key) ?? []
        return stored.compactMap { try? SearchQuery($0) }
    }

    func save(_ searches: [SearchQuery]) async throws {
        defaults.set(searches.map(\.value), forKey: Self.key)
    }
}
