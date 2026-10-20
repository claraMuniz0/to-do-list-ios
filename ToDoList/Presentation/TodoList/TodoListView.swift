import SwiftUI

/// Root screen: renders the view model's state and forwards intent to it and the router.
struct TodoListView: View {
    let viewModel: TodoListViewModel
    let router: AppRouter

    var body: some View {
        NavigationStack {
            content
        }
        .task { await viewModel.load() }
        .fullScreenCover(item: Binding(get: { router.presentedRoute }, set: { if $0 == nil { router.dismiss() } })) { route in
            switch route {
            case .addTodoItem:
                AddTodoItemPlaceholderView(onClose: router.dismiss)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            DSGradient.welcome.linearGradient.ignoresSafeArea()
                .accessibilityElement()
                .accessibilityLabel("Loading tasks")
        case .empty:
            WelcomeView(onAddFirstTask: { router.present(.addTodoItem(prefill: "")) })
        case .loaded(let sections):
            Text("\(sections.todo.count) tasks")
        case .error:
            TodoListErrorView(onRetry: { Task { await viewModel.retry() } })
        }
    }
}
