@testable import MyApp

/// Returns a queued outcome and records what it was asked, so use case and view model tests never reach Claude.
final class FakeStepSuggester: StepSuggesting {
    struct Call: Equatable {
        let title: String
        let description: String?
        let existingSteps: [String]
    }

    var outcome: Result<[StepTitle], StepSuggestionError>
    private(set) var calls: [Call] = []

    init(titles: [String] = []) {
        outcome = .success(titles.map { try! StepTitle($0) })
    }

    func suggest(title: String, description: String?, existingSteps: [StepTitle]) async throws -> [StepTitle] {
        calls.append(Call(title: title, description: description, existingSteps: existingSteps.map(\.value)))
        return try outcome.get()
    }
}
