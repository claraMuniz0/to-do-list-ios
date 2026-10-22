/// Asks for steps and returns only the ones that can still be added: new titles, within the list's capacity.
/// - Throws: whatever the `StepSuggesting` port throws, unchanged.
struct SuggestStepsUseCase {
    private let suggester: StepSuggesting

    init(suggester: StepSuggesting) {
        self.suggester = suggester
    }

    func execute(title: String, description: String?, existing: StepList) async throws -> [StepTitle] {
        let room = StepList.maxSteps - existing.steps.count
        guard room > 0 else { return [] }
        let suggested = try await suggester.suggest(
            title: title, description: description, existingSteps: existing.steps.map(\.title)
        )
        var seen = Set(existing.steps.map { Self.key($0) })
        var result: [StepTitle] = []
        for candidate in suggested where seen.insert(Self.key(candidate)).inserted {
            result.append(candidate)
            if result.count == room { break }
        }
        return result
    }

    private static func key(_ title: StepTitle) -> String { title.value.lowercased() }

    private static func key(_ step: Step) -> String { key(step.title) }
}
