/// Why a suggestion could not be produced; the only failures Domain knows, so it stays free of any Claude type.
enum StepSuggestionError: Error, Equatable {
    case offline
    case failed
}

/// Port for anything that can propose steps for a task. `existingSteps` lets the implementation avoid repeats.
protocol StepSuggesting {
    func suggest(title: String, description: String?, existingSteps: [StepTitle]) async throws -> [StepTitle]
}
