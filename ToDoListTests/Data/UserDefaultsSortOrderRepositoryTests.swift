import Foundation
import Testing
@testable import MyApp

struct UserDefaultsSortOrderRepositoryTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "UserDefaultsSortOrderRepositoryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func nothingSavedGivesTheDefaultOrder() {
        #expect(UserDefaultsSortOrderRepository(defaults: makeDefaults()).sortOrder() == .dueDate)
    }

    @Test func aSavedOrderIsReadBack() {
        let repository = UserDefaultsSortOrderRepository(defaults: makeDefaults())
        repository.save(.titleAZ)
        #expect(repository.sortOrder() == .titleAZ)
    }

    @Test func theChoiceSurvivesANewRepositoryOnTheSameStore() {
        let defaults = makeDefaults()
        UserDefaultsSortOrderRepository(defaults: defaults).save(.newestFirst)
        #expect(UserDefaultsSortOrderRepository(defaults: defaults).sortOrder() == .newestFirst)
    }

    @Test func anUnknownStoredValueFallsBackToTheDefault() {
        let defaults = makeDefaults()
        defaults.set("bogus", forKey: UserDefaultsSortOrderRepository.key)
        #expect(UserDefaultsSortOrderRepository(defaults: defaults).sortOrder() == .dueDate)
    }
}
