import SwiftUI

@main struct ToDoListApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            ContentView()
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
