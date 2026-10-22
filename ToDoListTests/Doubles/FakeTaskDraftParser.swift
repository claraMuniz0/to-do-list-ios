@testable import MyApp

/// Returns a queued outcome and records what it was asked, so use case and view model tests never reach Claude.
final class FakeTaskDraftParser: TaskDraftParsing {
    struct Call: Equatable {
        let text: String
        let context: SmartAddContext
    }

    var outcome: Result<TaskDraft, SmartAddError>
    private(set) var calls: [Call] = []

    init(draft: TaskDraft? = nil) {
        outcome = .success(draft ?? TaskDraft(
            title: try! TodoItemTitle("Dentist"), description: nil,
            categoryID: Category.personal.id, dueDate: nil, steps: []
        ))
    }

    func parse(_ text: SmartAddText, context: SmartAddContext) async throws -> TaskDraft {
        calls.append(Call(text: text.value, context: context))
        return try outcome.get()
    }
}
