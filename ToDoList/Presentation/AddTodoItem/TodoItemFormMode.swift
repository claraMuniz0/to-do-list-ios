/// Whether the form creates a task or edits the stored one with that id.
enum TodoItemFormMode: Equatable {
    case add
    case edit(TodoItemID)
}
