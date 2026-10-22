import SwiftUI

/// Root screen: renders the view model's state and forwards intent to it and the router.
struct TodoListView: View {
    let viewModel: TodoListViewModel
    let router: AppRouter
    let makeFormViewModel: (TodoItemFormMode, String) -> TodoItemFormViewModel
    let makeSearchViewModel: () -> TodoSearchViewModel

    @State private var quickAddText = ""
    /// Only one row can be swiped open at a time; opening another closes the first.
    @State private var openSwipeID: TodoItemID?
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
        .fullScreenCover(item: Binding(get: { router.presentedRoute }, set: { if $0 == nil { router.dismissAll() } })) { route in
            switch route {
            case .addTodoItem(let prefill):
                TodoItemFormCover(makeViewModel: { makeFormViewModel(.add, prefill) }, onFinish: finishForm)
                
            case .editTodoItem(let id):
                TodoItemFormCover(
                    makeViewModel: { makeFormViewModel(.edit(id), "") },
                    onFinish: finishForm,
                    isEditFlow: true
                )

            case .search:
                TodoSearchCover(
                    makeViewModel: makeSearchViewModel,
                    router: router,
                    sortOrder: viewModel.sortOrder,
                    reloadList: { await viewModel.load() },
                    onDeleted: { item in await viewModel.didDelete(item) },
                    nestedCover: { route, onFinish in nestedCover(route, onFinish: onFinish) }
                )
            }
        }
        .overlay(alignment: .bottom) {
            if !isListLoaded { undoToast.padding(.bottom, 24) }
        }
        .animation(UndoToastPolicy.slides(reduceMotion: reduceMotion) ? .default : nil, value: viewModel.undoState)
        // The list swaps silently for VoiceOver users otherwise.
        .onChange(of: viewModel.isAllCaughtUp) { _, isOn in
            if isOn { AccessibilityNotification.Announcement("All caught up").post() }
        }
        .onChange(of: viewModel.emptyFilterMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
    }

    @ViewBuilder private func nestedCover(_ route: AppRoute, onFinish: @escaping (TodoItemFormOutcome) -> Void) -> some View {
        switch route {
        case .addTodoItem(let prefill):
            TodoItemFormCover(makeViewModel: { makeFormViewModel(.add, prefill) }, onFinish: onFinish)
        case .editTodoItem(let id):
            TodoItemFormCover(makeViewModel: { makeFormViewModel(.edit(id), "") }, onFinish: onFinish, isEditFlow: true)
        case .search:
            EmptyView()
        }
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

    /// System menu with a checkmark on the active order. Same 44pt circular surface button as the other header icons.
    private var sortMenu: some View {
        Menu {
            Picker("Sort by", selection: Binding(get: { viewModel.sortOrder }, set: { viewModel.selectSortOrder($0) })) {
                ForEach(TodoItemSortOrder.allCases, id: \.self) { order in
                    Text(order.title).tag(order)
                }
            }
        } label: {
            CircularIconButtonLabel(systemImage: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort")
        .accessibilityValue(viewModel.sortOrder.title)
        .accessibilityHint("Choose how tasks are ordered")
    }

    /// Opens Search over the list. Search is independent of the list filters, so this reads and changes none of them.
    private var searchButton: some View {
        CircularIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search", accessibilityHint: "Find a task") {
            router.present(.search)
        }
    }

    private func list(_ sections: TodoListSections) -> some View {
        let visible = viewModel.visibleSections
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    ScreenHeader(subtitle: viewModel.subtitle, title: "My Tasks")
                    HStack(spacing: 8) {
                        searchButton
                        sortMenu
                    }
                }
                .padding(.bottom, 8)
                filterPills
                if viewModel.isCategoriesPanelOpen { categoriesPanel }
                if viewModel.isAllCaughtUp {
                    AllCaughtUpView(
                        message: viewModel.allCaughtUpMessage,
                        viewCompletedTitle: viewModel.viewCompletedTitle,
                        onViewCompleted: { viewModel.viewCompleted() }
                    )
                } else if case .category(let category) = viewModel.selectedFilter {
                    categoryResults(category, visible)
                } else if let message = viewModel.emptyFilterMessage {
                    emptyMessage(message)
                } else {
                    section("To do", items: visible.todo, isDone: false)
                    section("Completed", items: visible.completed, isDone: true)
                }
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
    private func categoryResults(_ category: Category, _ visible: TodoListSections) -> some View {
        if let message = viewModel.emptyFilterMessage {
            SectionHeader(title: "Showing · \(category.name.value)").padding(.top, 8)
            emptyMessage(message)
        } else {
            section("Showing · \(category.name.value)", items: visible.todo, isDone: false, showsCount: false)
        }
    }

    private func emptyMessage(_ message: String) -> some View {
        Text(message)
            .dsFont(.inputText)
            .foregroundStyle(DSColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
    }

    private var filterPills: some View {
        // At accessibility sizes the row would scroll off-screen unseen, so it wraps into a column instead.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { pills }
            VStack(alignment: .leading, spacing: 8) { pills }
        }
    }

    @ViewBuilder private var pills: some View {
        pill("All", .all)
        pill("Active", .active)
        pill("Done", .done)
        FilterPill(title: "Categories", isSelected: viewModel.isCategoriesPanelOpen, isExpanded: viewModel.isCategoriesPanelOpen) {
            viewModel.toggleCategories()
        }
    }

    private func pill(_ title: String, _ filter: TodoListFilter) -> some View {
        FilterPill(title: title, isSelected: viewModel.selectedFilter == filter) { viewModel.select(filter) }
    }

    @ViewBuilder private var categoriesPanel: some View {
        SectionHeader(title: "Categories").padding(.top, 8)
        ForEach(viewModel.categoryCounts, id: \.category) { entry in
            CategoryFilterRow(
                name: entry.category.name.value,
                openCount: entry.openCount,
                palette: ChipPalette(colorKey: entry.category.color.key),
                isSelected: viewModel.selectedFilter == .category(entry.category)
            ) { viewModel.selectCategory(entry.category) }
        }
    }

    @ViewBuilder
    private func section(_ title: String, items: [TodoItem], isDone: Bool, showsCount: Bool = true) -> some View {
        if !items.isEmpty {
            SectionHeader(title: title, count: showsCount ? items.count : nil)
                .padding(.top, 8)
            ForEach(items, id: \.id) { item in
                SwipeToDeleteRow(
                    isOpen: openSwipeID == item.id,
                    taskTitle: item.title.value,
                    onOpenChange: { setSwipe(open: $0, for: item.id) },
                    onDelete: {
                        openSwipeID = nil
                        Task { await viewModel.delete(id: item.id) }
                    }
                ) {
                    TaskRow(
                        title: item.title.value,
                        description: item.description,
                        categoryName: item.category.name.value,
                        palette: ChipPalette(colorKey: item.category.color.key),
                        isDone: isDone,
                        onOpen: { router.present(.editTodoItem(id: item.id)) },
                        onToggle: { Task { await viewModel.toggle(id: item.id) } }
                    )
                }
                // A toggled row changes section; without a state-dependent identity LazyVStack reuses it and keeps the old look.
                .id("\(item.id.uuid)-\(isDone)")
            }
        }
    }

    private func setSwipe(open: Bool, for id: TodoItemID) {
        if open {
            openSwipeID = id
        } else if openSwipeID == id {
            openSwipeID = nil
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

/// Holds the search view model in `@State` so it lives as long as the Search cover, and routes the forms that open
/// over it: saved re-runs the query and reloads the list, deleted closes Search so the list shows Undo.
private struct TodoSearchCover<Nested: View>: View {
    @State private var viewModel: TodoSearchViewModel
    let router: AppRouter
    let sortOrder: TodoItemSortOrder
    let reloadList: () async -> Void
    let onDeleted: (TodoItem) async -> Void
    let nestedCover: (AppRoute, @escaping (TodoItemFormOutcome) -> Void) -> Nested

    init(
        makeViewModel: () -> TodoSearchViewModel,
        router: AppRouter,
        sortOrder: TodoItemSortOrder,
        reloadList: @escaping () async -> Void,
        onDeleted: @escaping (TodoItem) async -> Void,
        nestedCover: @escaping (AppRoute, @escaping (TodoItemFormOutcome) -> Void) -> Nested
    ) {
        _viewModel = State(initialValue: makeViewModel())
        self.router = router
        self.sortOrder = sortOrder
        self.reloadList = reloadList
        self.onDeleted = onDeleted
        self.nestedCover = nestedCover
    }

    var body: some View {
        TodoSearchView(viewModel: viewModel, router: router, sortOrder: sortOrder)
            // Cover over cover: Add and Edit open above Search and close back to it.
            .fullScreenCover(item: Binding(get: { router.nestedRoute }, set: { if $0 == nil { router.dismissNested() } })) { route in
                nestedCover(route, finish)
            }
    }

    private func finish(_ outcome: TodoItemFormOutcome) {
        switch outcome {
        case .saved:
            router.dismissNested()
            Task {
                await viewModel.didFinishForm(.saved)
                await reloadList()
            }
        case .deleted(let item):
            router.dismissAll()
            Task { await onDeleted(item) }
        case .cancelled:
            router.dismissNested()
        }
    }
}

/// Holds the form's view model in `@State` so it is created once per presentation, not on every list re-render.
private struct TodoItemFormCover: View {
    @State private var viewModel: TodoItemFormViewModel
    @State private var isEditFlow: Bool
    let onFinish: (TodoItemFormOutcome) -> Void

    init(
        makeViewModel: () -> TodoItemFormViewModel,
        onFinish: @escaping (TodoItemFormOutcome) -> Void,
        isEditFlow: Bool = false
    ) {
        _viewModel = State(initialValue: makeViewModel())
        self.onFinish = onFinish
        self.isEditFlow = isEditFlow
    }

    var body: some View {
        TodoItemFormView(viewModel: viewModel, onFinish: onFinish, isEditFlow: isEditFlow)
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
    var filter: TodoListFilter = .all
    @State private var viewModel: TodoListViewModel?
    @State private var searchViewModel: TodoSearchViewModel?
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if let viewModel {
                TodoListView(viewModel: viewModel, router: router, makeFormViewModel: { _, title in .preview(title: title) }, makeSearchViewModel: { searchViewModel ?? AppDependencies(todoItemRepository: InMemoryTodoItemRepository(), dateProvider: PreviewDateProvider()).makeTodoSearchViewModel() })
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
            let dependencies = AppDependencies(todoItemRepository: repository, dateProvider: PreviewDateProvider())
            searchViewModel = dependencies.makeTodoSearchViewModel()
            viewModel = dependencies.makeTodoListViewModel()
            await viewModel?.load()
            viewModel?.select(filter)
        }
    }
}

#Preview("Mixed") { TodoListPreviewHost(openCount: 3, completedCount: 2) }
#Preview("Only open") { TodoListPreviewHost(openCount: 3, completedCount: 0) }
#Preview("Only completed") { TodoListPreviewHost(openCount: 0, completedCount: 2) }
#Preview("All caught up") { TodoListPreviewHost(openCount: 0, completedCount: 2) }
#Preview("Filter - Done, empty") { TodoListPreviewHost(openCount: 3, completedCount: 0, filter: .done) }
#Preview("Filter - Empty category") { TodoListPreviewHost(openCount: 0, completedCount: 2, filter: .category(.shopping)) }
#Preview("Filter - Active") { TodoListPreviewHost(openCount: 3, completedCount: 2, filter: .active) }
#Preview("Filter - Done") { TodoListPreviewHost(openCount: 3, completedCount: 2, filter: .done) }
#Preview("Filter - Categories") { TodoListPreviewHost(openCount: 3, completedCount: 2, filter: .category(.work)) }
#Preview("Accessibility3") {
    TodoListPreviewHost(openCount: 3, completedCount: 2).dynamicTypeSize(.accessibility3)
}
#endif
