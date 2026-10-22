import Foundation

/// How many of a task's steps are done. `TodoItem` returns `nil` instead of a progress with zero steps,
/// so `total` is always at least 1 for a value that reaches the UI.
struct StepsProgress: Equatable {
    let done: Int
    let total: Int

    var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }
    var isComplete: Bool { total > 0 && done == total }
    /// The "2 of 5" text shown beside the Steps header.
    var label: String { "\(done) of \(total)" }
}
