import SwiftUI

@main struct ToDoListApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
