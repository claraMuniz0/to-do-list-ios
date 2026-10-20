import SwiftUI

@main struct ToDoListApp: App {
    private let dependencies = AppDependencies.live()

    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
