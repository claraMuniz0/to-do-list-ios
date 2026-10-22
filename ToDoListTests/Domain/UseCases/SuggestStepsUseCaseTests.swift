import Testing
@testable import MyApp

struct SuggestStepsUseCaseTests {
    private func list(_ titles: [String]) -> StepList {
        StepList(titles.map { Step(title: try! StepTitle($0)) })
    }

    private func run(
        suggested: [String], existing: [String] = []
    ) async throws -> (titles: [String], suggester: FakeStepSuggester) {
        let suggester = FakeStepSuggester(titles: suggested)
        let result = try await SuggestStepsUseCase(suggester: suggester)
            .execute(title: "Plan trip", description: "Lisbon", existing: list(existing))
        return (result.map(\.value), suggester)
    }

    @Test func asksTheSuggesterWithTheTaskAndItsExistingSteps() async throws {
        let (_, suggester) = try await run(suggested: ["Book flights"], existing: ["Pick dates"])
        #expect(suggester.calls == [.init(title: "Plan trip", description: "Lisbon", existingSteps: ["Pick dates"])])
    }

    @Test func returnsTheSuggestedTitlesInOrder() async throws {
        let (titles, _) = try await run(suggested: ["Book flights", "Reserve hotel"])
        #expect(titles == ["Book flights", "Reserve hotel"])
    }

    @Test func dropsTitlesAlreadyInTheListIgnoringCase() async throws {
        let (titles, _) = try await run(suggested: ["pick dates", "Book flights"], existing: ["Pick dates"])
        #expect(titles == ["Book flights"])
    }

    @Test func dropsDuplicatesWithinTheSuggestion() async throws {
        let (titles, _) = try await run(suggested: ["Book flights", "BOOK FLIGHTS", "Reserve hotel"])
        #expect(titles == ["Book flights", "Reserve hotel"])
    }

    @Test func keepsOnlyAsManyAsTheListHasRoomFor() async throws {
        let existing = (1...18).map { "Step \($0)" }
        let (titles, _) = try await run(suggested: ["A", "B", "C", "D"], existing: existing)
        #expect(titles == ["A", "B"])
    }

    @Test func returnsNothingWhenTheListIsFull() async throws {
        let existing = (1...20).map { "Step \($0)" }
        let (titles, _) = try await run(suggested: ["A"], existing: existing)
        #expect(titles.isEmpty)
    }

    @Test func passesSuggesterFailuresThrough() async {
        let suggester = FakeStepSuggester()
        suggester.outcome = .failure(.offline)
        await #expect(throws: StepSuggestionError.offline) {
            try await SuggestStepsUseCase(suggester: suggester).execute(title: "T", description: nil, existing: StepList())
        }
    }
}
