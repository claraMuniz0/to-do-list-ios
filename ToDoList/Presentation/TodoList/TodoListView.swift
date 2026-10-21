import SwiftUI

/// Root screen: renders the view model's state and forwards intent to it and the router.
struct TodoListView: View {
    let viewModel: TodoListViewModel
    let router: AppRouter
    let makeFormViewModel: (TodoItemFormMode, String) -> TodoItemFormViewModel

    @State private var quickAddText = ""
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverIsOn
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControlIsOn
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            content
        }
        .task { await viewModel.load() }
        // The Add Task cover hides the bar without removing it, so close the keyboard when it opens.
        .onChange(of: router.presentedRoute) { _, route in
            if route != nil { UIApplication.shared.dismissKeyboard() }
        }
        .fullScreenCover(item: Binding(get: { router.presentedRoute }, set: { if $0 == nil { router.dismiss() } })) { route in
            switch route {
            case .addTodoItem(let prefill):
                TodoItemFormCover(makeViewModel: { makeFormViewModel(.add, prefill) }, onFinish: finishForm)
            case .editTodoItem(let id):
                TodoItemFormCover(makeViewModel: { makeFormViewModel(.edit(id), "") }, onFinish: finishForm)
            }
        }
        .overlay(alignment: .bottom) {
            if !isListLoaded { undoToast.padding(.bottom, 24) }
        }
        .animation(UndoToastPolicy.slides(reduceMotion: reduceMotion) ? .default : nil, value: viewModel.undoState)
    }

    private var isListLoaded: Bool {
        if case .loaded = viewModel.state { return true }
        return false
    }

    private func finishForm(_ outcome: TodoItemFormOutcome) {
        router.dismiss()
        switch outcome {
        case .saved: Task { await viewModel.load() }
        case .deleted(let item): Task { await viewModel.didDelete(item) }
        case .cancelled: break
        }
    }

    /// Visible for 5 seconds (until used when VoiceOver or Switch Control is on); `.task(id:)` restarts the timer
    /// when a second delete replaces the toast.
    @ViewBuilder private var undoToast: some View {
        if let undo = viewModel.undoState {
            UndoToast(message: "Task deleted") { Task { await viewModel.undo() } }
                .padding(.horizontal, 20)
                .transition(UndoToastPolicy.slides(reduceMotion: reduceMotion) ? .move(edge: .bottom).combined(with: .opacity) : .opacity)
                .task(id: undo) {
                    // A cancelled sleep means a newer toast or a dismissal took over, so ending the timer is correct.
                    try? await Task.sleep(for: UndoToastPolicy.announcementDelay)
                    guard !Task.isCancelled else { return }
                    AccessibilityNotification.Announcement("Deleted \(undo.item.title.value). Undo available.").post()
                    let assistiveTechnologyIsOn = voiceOverIsOn || switchControlIsOn
                    guard let delay = UndoToastPolicy.autoDismissDelay(assistiveTechnologyIsOn: assistiveTechnologyIsOn) else { return }
                    try? await Task.sleep(for: delay)
                    if !Task.isCancelled { viewModel.dismissUndo() }
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
            list(sections)
        case .error:
            TodoListErrorView(onRetry: { Task { await viewModel.retry() } })
        }
    }

    private func list(_ sections: TodoListSections) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ScreenHeader(subtitle: viewModel.subtitle, title: "My Tasks")
                    .padding(.bottom, 8)
                section("To do", items: sections.todo, isDone: false)
                section("Completed", items: sections.completed, isDone: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .safeAreaInset(edge: .bottom, spacing: 0) { quickAdd }
    }

    @ViewBuilder
    private func section(_ title: String, items: [TodoItem], isDone: Bool) -> some View {
        if !items.isEmpty {
            SectionHeader(title: title, count: items.count)
                .padding(.top, 8)
            ForEach(items, id: \.id) { item in
                TaskRow(
                    title: item.title.value,
                    description: item.description,
                    categoryName: item.category.name.value,
                    palette: ChipPalette(colorKey: item.category.color.key),
                    isDone: isDone,
                    onOpen: { router.present(.editTodoItem(id: item.id)) },
                    onToggle: { Task { await viewModel.toggle(id: item.id) } }
                )
                // A toggled row changes section; without a state-dependent identity LazyVStack reuses it and keeps the old look.
                .id("\(item.id.uuid)-\(isDone)")
            }
        }
    }

    private var quickAdd: some View {
        VStack(spacing: 8) {
            undoToast
            if viewModel.actionFailed {
                Text("Something went wrong. Try again.")
                    .dsFont(.rowDescription)
                    .foregroundStyle(DSColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .onAppear { AccessibilityNotification.Announcement("Something went wrong. Try again.").post() }
            }
            AddTaskInput(
                text: $quickAddText,
                onOptions: { router.present(.addTodoItem(prefill: quickAddText)) },
                onAdd: addQuickly
            )
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
        .background(DSColor.bg)
        // The bar only exists in the loaded state; leaving it must not leave the keyboard open.
        .onDisappear { UIApplication.shared.dismissKeyboard() }
    }

    private func addQuickly() {
        let title = quickAddText
        
        Task {
            if await viewModel.quickAdd(title: title) { quickAddText = "" }
        }
    }
}

/// Holds the form's view model in `@State` so it is created once per presentation, not on every list re-render.
private struct TodoItemFormCover: View {
    @State private var viewModel: TodoItemFormViewModel
    let onFinish: (TodoItemFormOutcome) -> Void

    init(makeViewModel: () -> TodoItemFormViewModel, onFinish: @escaping (TodoItemFormOutcome) -> Void) {
        _viewModel = State(initialValue: makeViewModel())
        self.onFinish = onFinish
    }

    var body: some View {
        TodoItemFormView(viewModel: viewModel, onFinish: onFinish)
    }
}

#if DEBUG
private struct PreviewDateProvider: DateProvider {
    func now() -> Date { Date(timeIntervalSince1970: 1_791_460_800) } // 2026-10-08 12:00 UTC
}

/// Seeds an in-memory repository before showing the list, so the loaded state is deterministic.
private struct TodoListPreviewHost: View {
    let openCount: Int
    let completedCount: Int
    @State private var viewModel: TodoListViewModel?
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if let viewModel {
                TodoListView(viewModel: viewModel, router: router, makeFormViewModel: { _, title in .preview(title: title) })
            }
        }
        .task {
            let repository = InMemoryTodoItemRepository()
            let base = Date(timeIntervalSince1970: 1_791_000_000)
            let open = [
                ("Buy groceries", Category.shopping, "Milk, eggs and bread"),
                ("Prepare quarterly slides", Category.work, nil),
                ("Call the landlord about the broken heating system in the second bedroom", Category.personal, nil),
            ]
            let done = [("Send the invoice", Category.work), ("Book the dentist", Category.personal)]
            for (index, entry) in open.prefix(openCount).enumerated() {
                try? await repository.add(TodoItem(
                    title: try! TodoItemTitle(entry.0), description: entry.2, category: entry.1,
                    createdAt: base.addingTimeInterval(Double(index))
                ))
            }
            for (index, entry) in done.prefix(completedCount).enumerated() {
                try? await repository.add(TodoItem(
                    title: try! TodoItemTitle(entry.0), category: entry.1,
                    createdAt: base.addingTimeInterval(Double(index)),
                    completedAt: base.addingTimeInterval(Double(100 + index))
                ))
            }
            viewModel = AppDependencies(todoItemRepository: repository, dateProvider: PreviewDateProvider())
                .makeTodoListViewModel()
        }
    }
}

#Preview("Mixed") { TodoListPreviewHost(openCount: 3, completedCount: 2) }
#Preview("Only open") { TodoListPreviewHost(openCount: 3, completedCount: 0) }
#Preview("Only completed") { TodoListPreviewHost(openCount: 0, completedCount: 2) }
#Preview("Accessibility3") {
    TodoListPreviewHost(openCount: 3, completedCount: 2).dynamicTypeSize(.accessibility3)
}
#endif
