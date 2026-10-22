import Observation

/// Where the Describe screen is: ready for input, waiting for Claude, or showing why it failed.
enum SmartAddState: Equatable {
    case idle
    case loading
    case failed(SmartAddError)
}

/// State and intent of the Smart add Describe screen. "Fill it in" stays disabled until the text has content;
/// a failure keeps the typed text so the user can try again.
@MainActor @Observable
final class SmartAddViewModel {
    static let examples = ["Buy milk tomorrow morning", "Team sync Friday 10am, work", "Mom's gift by next week"]

    private(set) var state = SmartAddState.idle
    private var storedInput = ""
    private let categories: [Category]
    private let parseTaskDraft: ParseTaskDraftUseCase

    init(parseTaskDraft: ParseTaskDraftUseCase, categories: [Category] = Category.defaults) {
        self.parseTaskDraft = parseTaskDraft
        self.categories = categories
    }

    /// Typing past `SmartAddText.maxLength` is cut off; changing the text dismisses a shown error.
    var input: String {
        get { storedInput }
        set {
            storedInput = String(newValue.prefix(SmartAddText.maxLength))
            if case .failed = state { state = .idle }
        }
    }

    var counterText: String { "\(storedInput.count) / \(SmartAddText.maxLength)" }

    /// "/" is read badly by VoiceOver, so the count gets its own spoken form.
    var spokenCounterText: String { "\(storedInput.count) of \(SmartAddText.maxLength) characters" }

    var canFill: Bool { !SmartAddText.isBlank(storedInput) && state != .loading }

    var isLoading: Bool { state == .loading }

    var errorMessage: String? {
        guard case .failed(let error) = state else { return nil }
        switch error {
        case .couldNotUnderstand: return "I couldn't turn that into a task. Try saying it another way."
        case .offline: return "You're offline. Check your connection and try again."
        case .failed: return "Something went wrong. Try again."
        }
    }

    func selectExample(_ example: String) { input = example }

    /// Returns the draft to review, or nil when the input is blank, the request failed (`state` says why) or the
    /// surrounding task was cancelled, for instance by closing the screen.
    func fill() async -> TaskDraft? {
        guard canFill else { return nil }
        state = .loading
        do {
            let draft = try await parseTaskDraft.execute(text: storedInput, categories: categories)
            guard !Task.isCancelled else { state = .idle; return nil }
            state = .idle
            return draft
        } catch {
            guard !Task.isCancelled else { state = .idle; return nil }
            state = .failed((error as? SmartAddError) ?? .failed)
            return nil
        }
    }
}
