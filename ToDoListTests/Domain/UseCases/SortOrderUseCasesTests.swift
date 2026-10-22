import Testing
@testable import MyApp

struct SortOrderUseCasesTests {
    @Test func getReturnsTheStoredOrder() {
        let spy = SortOrderRepositorySpy(stored: .titleAZ)
        #expect(GetSortOrderUseCase(repository: spy).execute() == .titleAZ)
    }

    @Test func getReturnsTheDefaultWhenNothingWasChosen() {
        #expect(GetSortOrderUseCase(repository: SortOrderRepositorySpy()).execute() == .default)
    }

    @Test func saveStoresTheChosenOrder() {
        let spy = SortOrderRepositorySpy()
        SaveSortOrderUseCase(repository: spy).execute(.newestFirst)
        #expect(spy.stored == .newestFirst)
        #expect(spy.saveCallCount == 1)
    }
}
