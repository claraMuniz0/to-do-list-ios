import Testing
@testable import MyApp

struct RecentSearchUseCasesTests {
    private func queries(_ texts: [String]) throws -> [SearchQuery] {
        try texts.map(SearchQuery.init)
    }

    private func values(_ spy: RecentSearchRepositorySpy) -> [String] {
        spy.storedSearches.map(\.value)
    }

    // MARK: - Get

    @Test func listsTheStoredSearchesNewestFirst() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries(["b", "a"])
        #expect(try await GetRecentSearchesUseCase(repository: spy).execute() == queries(["b", "a"]))
    }

    @Test func listsNothingWhenThereAreNoSearches() async throws {
        #expect(try await GetRecentSearchesUseCase(repository: RecentSearchRepositorySpy()).execute().isEmpty)
    }

    @Test func listPropagatesTheRepositoryError() async {
        let spy = RecentSearchRepositorySpy()
        spy.errorToThrow = StubFailure()
        await #expect(throws: StubFailure()) { try await GetRecentSearchesUseCase(repository: spy).execute() }
    }

    // MARK: - Record

    @Test func recordsANewSearchAtTheTop() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries(["a"])
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("b"))
        #expect(values(spy) == ["b", "a"])
    }

    @Test func recordsIntoAnEmptyList() async throws {
        let spy = RecentSearchRepositorySpy()
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("a"))
        #expect(values(spy) == ["a"])
    }

    @Test func movesARepeatedTermToTheTopInsteadOfDuplicating() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries(["c", "b", "a"])
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("a"))
        #expect(values(spy) == ["a", "c", "b"])
    }

    @Test func treatsCaseAndAccentVariantsAsTheSameTermKeepingTheNewSpelling() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries(["dentist", "cafe"])
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("CAFÉ"))
        #expect(values(spy) == ["CAFÉ", "dentist"])
    }

    @Test func keepsAtMostEightSearchesDroppingTheOldest() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries((1...8).map { "t\($0)" })
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("new"))
        #expect(RecordRecentSearchUseCase.maxCount == 8)
        #expect(values(spy) == ["new", "t1", "t2", "t3", "t4", "t5", "t6", "t7"])
    }

    @Test func repeatingATermWhenFullDropsNothing() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries((1...8).map { "t\($0)" })
        try await RecordRecentSearchUseCase(repository: spy).execute(SearchQuery("t8"))
        #expect(values(spy) == ["t8", "t1", "t2", "t3", "t4", "t5", "t6", "t7"])
    }

    @Test func recordPropagatesTheRepositoryError() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.errorToThrow = StubFailure()
        let query = try SearchQuery("a")
        await #expect(throws: StubFailure()) { try await RecordRecentSearchUseCase(repository: spy).execute(query) }
    }

    // MARK: - Clear

    @Test func clearsEverythingImmediately() async throws {
        let spy = RecentSearchRepositorySpy()
        spy.storedSearches = try queries(["a", "b"])
        try await ClearRecentSearchesUseCase(repository: spy).execute()
        #expect(spy.storedSearches.isEmpty)
    }

    @Test func clearPropagatesTheRepositoryError() async {
        let spy = RecentSearchRepositorySpy()
        spy.errorToThrow = StubFailure()
        await #expect(throws: StubFailure()) { try await ClearRecentSearchesUseCase(repository: spy).execute() }
    }
}
