import Foundation

/// One small action inside a task. Owned by `TodoItem`, which is the only place steps are added or removed.
struct Step: Equatable {
    let id: StepID
    private(set) var title: StepTitle
    private(set) var isDone: Bool

    init(id: StepID = StepID(), title: StepTitle, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }

    mutating func toggle() {
        isDone.toggle()
    }

    mutating func rename(_ newTitle: StepTitle) {
        title = newTitle
    }
}
