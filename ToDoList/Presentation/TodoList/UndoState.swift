/// The deleted task the toast can bring back. Equatable by item, so a second delete is a new state and restarts the view's timer.
struct UndoState: Equatable {
    let item: TodoItem
}
