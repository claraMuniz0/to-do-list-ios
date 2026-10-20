import SwiftData
import SwiftUI

@main struct ToDoListApp: App {
    @State private var viewModel: TodoListViewModel
    @State private var router = AppRouter()
    private let makeAddViewModel: (String) -> AddTodoItemViewModel

    init() {
        FontRegistrar.registerAll()
        // A store that cannot open is unrecoverable at launch; fail loudly rather than lose tasks silently.
        let dependencies: AppDependencies
        do { dependencies = try AppDependencies.live() } catch { fatalError("Could not open the task store: \(error)") }
        _viewModel = State(initialValue: dependencies.makeTodoListViewModel())
        makeAddViewModel = { dependencies.makeAddTodoItemViewModel(initialTitle: $0) }
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(viewModel: viewModel, router: router, makeAddViewModel: makeAddViewModel)
                .preferredColorScheme(.light)
        }
    }
}

/// Composition root: the only place concrete Data types are chosen.
extension AppDependencies {
    @MainActor
    static func live() throws -> AppDependencies {
        try make(container: .todoItems())
    }

    /// SwiftData in memory, for tests and previews.
    @MainActor
    static func inMemory() throws -> AppDependencies {
        try make(container: .inMemoryTodoItems())
    }

    @MainActor
    private static func make(container: ModelContainer) -> AppDependencies {
        AppDependencies(
            todoItemRepository: SwiftDataTodoItemRepository(container: container),
            dateProvider: SystemDateProvider()
        )
    }
}
