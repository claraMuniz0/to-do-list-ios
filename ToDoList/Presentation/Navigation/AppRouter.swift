import Observation

/// Destinations presented over the root screen.
enum AppRoute: Hashable, Identifiable {
    case addTodoItem(prefill: String)
    case editTodoItem(id: TodoItemID)
    case smartAdd
    case search

    var id: Self { self }

    /// Forms that open as a second cover when search is already showing.
    fileprivate var coversSearch: Bool {
        switch self {
        case .addTodoItem, .editTodoItem, .smartAdd: true
        case .search: false
        }
    }
}

/// Owns what is presented over the root screen: one cover, plus a second cover over Search for Add and Edit.
@MainActor @Observable
final class AppRouter {
    private(set) var presentedRoute: AppRoute?
    /// Add or Edit presented over the Search cover; always nil unless `presentedRoute == .search`.
    private(set) var nestedRoute: AppRoute?

    func present(_ route: AppRoute) {
        if route.coversSearch, presentedRoute == .search {
            nestedRoute = route
        } else {
            presentedRoute = route
            nestedRoute = nil
        }
    }

    /// Closes the topmost cover: the nested one when there is one, otherwise the base cover.
    func dismiss() {
        if nestedRoute != nil {
            nestedRoute = nil
        } else {
            presentedRoute = nil
        }
    }

    /// Closes only the cover over Search, leaving Search open.
    func dismissNested() {
        nestedRoute = nil
    }

    func dismissAll() {
        nestedRoute = nil
        presentedRoute = nil
    }
}
