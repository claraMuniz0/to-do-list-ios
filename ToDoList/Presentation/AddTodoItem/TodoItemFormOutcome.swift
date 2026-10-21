/// How the form screen ended, reported to the presenter (the list), which refreshes and, for a delete, offers Undo.
enum TodoItemFormOutcome: Equatable {
    case saved
    case deleted(TodoItem)
    case cancelled
}
