/// Whether the form creates a task, edits the stored one with that id, or creates one from a Smart add draft the user is reviewing.
/// Edit fields stay empty until the view model's `load()` finishes, so a slow load never shows another task's values.
enum TodoItemFormMode: Equatable {
    case add
    case edit(TodoItemID)
    case reviewingDraft(TaskDraft)
}
