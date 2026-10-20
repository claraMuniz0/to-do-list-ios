import Observation

/// Destinations presented over the root screen. Phase 4 adds the edit case.
enum AppRoute: Hashable, Identifiable {
    case addTodoItem

    var id: Self { self }
}

/// Owns what is presented over the root screen; one route at a time.
@MainActor @Observable
final class AppRouter {
    private(set) var presentedRoute: AppRoute?

    func present(_ route: AppRoute) {
        presentedRoute = route
    }

    func dismiss() {
        presentedRoute = nil
    }
}
