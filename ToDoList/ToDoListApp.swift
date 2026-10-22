import Foundation
import SwiftData
import SwiftUI

@main struct ToDoListApp: App {
    @State private var viewModel: TodoListViewModel
    @State private var router = AppRouter()
    private let makeFormViewModel: (TodoItemFormMode, String) -> TodoItemFormViewModel
    private let makeSearchViewModel: () -> TodoSearchViewModel

    init() {
        FontRegistrar.registerAll()
        // A store that cannot open is unrecoverable at launch; fail loudly rather than lose tasks silently.
        let dependencies: AppDependencies
        do { dependencies = try AppDependencies.live() } catch { fatalError("Could not open the task store: \(error)") }
        _viewModel = State(initialValue: dependencies.makeTodoListViewModel())
        makeFormViewModel = { dependencies.makeTodoItemFormViewModel(mode: $0, initialTitle: $1) }
        makeSearchViewModel = { dependencies.makeTodoSearchViewModel() }
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(viewModel: viewModel, router: router, makeFormViewModel: makeFormViewModel, makeSearchViewModel: makeSearchViewModel)
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

    /// SwiftData in memory and a throwaway UserDefaults suite, so tests never touch the app's real settings.
    @MainActor
    static func inMemory() throws -> AppDependencies {
        let suite = "AppDependencies.inMemory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return try make(container: .inMemoryTodoItems(), defaults: defaults)
    }

    @MainActor
    private static func make(container: ModelContainer, defaults: UserDefaults = .standard) -> AppDependencies {
        AppDependencies(
            todoItemRepository: SwiftDataTodoItemRepository(container: container),
            dateProvider: SystemDateProvider(),
            sortOrderRepository: UserDefaultsSortOrderRepository(defaults: defaults),
            recentSearchRepository: UserDefaultsRecentSearchRepository(defaults: defaults)
        )
    }
}
