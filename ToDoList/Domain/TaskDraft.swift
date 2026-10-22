import Foundation

/// What Claude understood from a sentence: valid domain data that is not saved until the user reviews it.
///
/// Normalises on creation so a draft never carries a blank description, repeated steps or more steps than
/// a `StepList` can hold.
struct TaskDraft: Equatable {
    let title: TodoItemTitle
    let description: String?
    let categoryID: CategoryID
    let dueDate: DueDate?
    let steps: [StepTitle]

    init(title: TodoItemTitle, description: String?, categoryID: CategoryID, dueDate: DueDate?, steps: [StepTitle]) {
        self.title = title
        let trimmed = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = trimmed?.isEmpty == false ? trimmed : nil
        self.categoryID = categoryID
        self.dueDate = dueDate
        var seen = Set<String>()
        self.steps = Array(steps.filter { seen.insert($0.value.lowercased()).inserted }.prefix(StepList.maxSteps))
    }
}
