/// Whether the form creates a task or edits the stored one with that id.
/// Edit fields stay empty until the view model's `load()` finishes, so a slow load never shows another task's values.
enum TodoItemFormMode: Equatable {
    case add
    case edit(TodoItemID)
}
