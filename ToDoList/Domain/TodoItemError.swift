import Foundation

enum TodoItemError: Error, Equatable {
    /// Adding a step beyond `TodoItem.maxSteps`.
    case tooManySteps
    case stepNotFound
    /// A step move whose source or target index is outside the current steps.
    case invalidStepPosition
}
