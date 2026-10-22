/// Why a sentence could not become a draft; the only failures Domain knows, so it stays free of any Claude type.
enum SmartAddError: Error, Equatable {
    case couldNotUnderstand
    case offline
    case failed
}

/// Port for anything that can turn a sentence into a task draft.
protocol TaskDraftParsing {
    func parse(_ text: SmartAddText, context: SmartAddContext) async throws -> TaskDraft
}
