import SwiftUI

@main struct ToDoListApp: App {
    @State private var viewModel: TodoListViewModel
    @State private var router = AppRouter()

    init() {
        FontRegistrar.registerAll()
        let dependencies = AppDependencies.live()
        _viewModel = State(initialValue: dependencies.makeTodoListViewModel())
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(viewModel: viewModel, router: router)
                .preferredColorScheme(.light)
        }
    }
}

/// Composition root: the only place concrete Data types are chosen.
extension AppDependencies {
    static func live() -> AppDependencies {
        AppDependencies(
            todoItemRepository: InMemoryTodoItemRepository(),
            dateProvider: SystemDateProvider()
        )
    }
}
