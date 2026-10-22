import Foundation

/// An ordered, bounded list of steps. The one place the step rules live, shared by `TodoItem` and by
/// forms that edit steps before the task is saved.
struct StepList: Equatable {
    /// Keeps a task usable and stops Claude from flooding it.
    static let maxSteps = 20

    private(set) var steps: [Step]

    /// Steps past `maxSteps` are dropped so the limit holds even for stored data.
    init(_ steps: [Step] = []) {
        self.steps = Array(steps.prefix(Self.maxSteps))
    }

    /// `nil` when empty, so views never show an empty "0 of 0" bar.
    var progress: StepsProgress? {
        steps.isEmpty ? nil : StepsProgress(done: steps.filter(\.isDone).count, total: steps.count)
    }

    /// - Throws: `TodoItemError.tooManySteps` once the list already has `maxSteps`.
    @discardableResult
    mutating func add(_ title: StepTitle) throws -> StepID {
        guard steps.count < Self.maxSteps else { throw TodoItemError.tooManySteps }
        let step = Step(title: title)
        steps.append(step)
        return step.id
    }

    mutating func toggle(_ id: StepID) throws {
        try update(id) { $0.toggle() }
    }

    mutating func rename(_ id: StepID, to newTitle: StepTitle) throws {
        try update(id) { $0.rename(newTitle) }
    }

    mutating func remove(_ id: StepID) throws {
        steps.remove(at: try index(of: id))
    }

    /// `destination` is the index the step ends up at, so moving the first of three to `2` puts it last.
    mutating func move(from source: Int, to destination: Int) throws {
        guard steps.indices.contains(source), steps.indices.contains(destination) else {
            throw TodoItemError.invalidStepPosition
        }
        steps.insert(steps.remove(at: source), at: destination)
    }

    private mutating func update(_ id: StepID, _ change: (inout Step) -> Void) throws {
        change(&steps[try index(of: id)])
    }

    private func index(of id: StepID) throws -> Int {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { throw TodoItemError.stepNotFound }
        return index
    }
}
