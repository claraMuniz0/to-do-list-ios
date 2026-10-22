import SwiftUI

/// Copy of the search screen, kept apart from the view so it is easy to check.
enum TodoSearchCopy {
    static let recentTitle = "Recent"
    static let clearAll = "Clear all"
    static let byCategoryTitle = "By category"
    static let noResultsTitle = "No tasks found"
    static let noResultsMessage = "Try a different word, or add it as a new task."

    /// Curly quotes as in the design; the button truncates a long title in the middle.
    static func addAsTaskTitle(_ title: String) -> String { "Add \u{201C}\(title)\u{201D} as a task" }
}

/// Full-screen search: Recent, Results and No Results states. Renders the view model and forwards intent to it;
/// Add and Edit open through the router (as a cover over this one).
struct TodoSearchView: View {
    let viewModel: TodoSearchViewModel
    let router: AppRouter
    /// The list's current sort order, applied to the results when Search opens.
    let sortOrder: TodoItemSortOrder

    @FocusState private var isFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                text: Binding(get: { viewModel.query }, set: { text in Task { await viewModel.setQuery(text) } }),
                isFocused: $isFieldFocused,
                onSubmit: submit,
                onCancel: { router.dismiss() }
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            content
        }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
        .accessibilityAction(.escape) { router.dismiss() }
        .task {
            viewModel.setSortOrder(sortOrder)
            await viewModel.load()
        }
        .onAppear { isFieldFocused = true }
        .onChange(of: viewModel.announcement) { _, announcement in
            if let announcement { AccessibilityNotification.Announcement(announcement.text).post() }
        }
    }

    private func submit() {
        isFieldFocused = false
        Task { await viewModel.submit() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .recent:
            scrolling(spacing: 28) { recent }
        case .results(let items):
            scrolling(spacing: 10) { results(items) }
        case .noResults:
            scrolling(spacing: 12) { noResults }
        case .error:
            TodoListErrorView(onRetry: { Task { await viewModel.setQuery(viewModel.query) } })
        }
    }

    /// The scroll view shrinks with the keyboard, so content (and the no-results button) stays visible.
    private func scrolling<Content: View>(spacing: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) { content() }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Recent

    @ViewBuilder private var recent: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(
                    title: TodoSearchCopy.recentTitle,
                    trailingAction: (TodoSearchCopy.clearAll, { Task { await viewModel.clearAllRecentSearches() } }),
                    trailingAccessibilityLabel: "Clear all recent searches"
                )
                VStack(spacing: 0) {
                    let terms = viewModel.recentSearches
                    ForEach(Array(terms.enumerated()), id: \.offset) { index, term in
                        RecentSearchRow(
                            term: term.value,
                            showsDivider: index < terms.count - 1,
                            onSelect: { Task { await viewModel.selectRecent(term) } },
                            onFill: { Task { await viewModel.fill(term) } }
                        )
                    }
                }
            }
        }
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: TodoSearchCopy.byCategoryTitle)
            // At accessibility sizes the chips would run off the edge, so they stack instead.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { categoryChips }
                VStack(alignment: .leading, spacing: 10) { categoryChips }
            }
        }
    }

    @ViewBuilder private var categoryChips: some View {
        ForEach(Category.defaults, id: \.self) { category in
            scopeButton(for: category, hint: viewModel.scope == category ? "Removes the category filter" : "Shows only this category")
        }
    }

    /// The tap area and the VoiceOver semantics live on the button, so they do not depend on how the chip's own
    /// accessibility element merges into it.
    private func scopeButton(for category: Category, hint: String) -> some View {
        Button { Task { await viewModel.toggleScope(category) } } label: {
            chip(for: category)
                .frame(minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name.value)
        .accessibilityAddTraits(viewModel.scope == category ? .isSelected : [])
        .accessibilityHint(hint)
    }

    private func chip(for category: Category) -> some View {
        CategoryChip(
            style: .option,
            isSelected: viewModel.scope == category,
            label: category.name.value,
            palette: ChipPalette(colorKey: category.color.key)
        )
    }

    // MARK: Results

    @ViewBuilder private func results(_ items: [TodoItem]) -> some View {
        scopeChip
        if let count = viewModel.resultCountText {
            SectionHeader(title: count)
        }
        ForEach(items, id: \.id) { item in
            TaskRow(
                title: item.title.value,
                description: item.description,
                categoryName: item.category.name.value,
                palette: ChipPalette(colorKey: item.category.color.key),
                isDone: item.isCompleted,
                onOpen: { open(item) },
                onToggle: { Task { await viewModel.toggle(id: item.id) } }
            )
        }
    }

    private func open(_ item: TodoItem) {
        Task {
            await viewModel.didSelectResult()
            router.present(.editTodoItem(id: item.id))
        }
    }

    /// The selected category above the header; tapping it removes the scope.
    @ViewBuilder private var scopeChip: some View {
        if let scope = viewModel.scope {
            scopeButton(for: scope, hint: "Removes the category filter")
        }
    }

    // MARK: No results

    @ViewBuilder private var noResults: some View {
        scopeChip
        VStack(spacing: 16) {
            EmptyStateIllustration(symbol: "magnifyingglass", layout: .noResults)
            Text(TodoSearchCopy.noResultsTitle)
                .dsFont(.emptyTitle)
                .foregroundStyle(DSColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(TodoSearchCopy.noResultsMessage)
                .dsFont(.inputText)
                .foregroundStyle(DSColor.textSecondary)
                .multilineTextAlignment(.center)
            if let title = viewModel.addAsTaskTitle {
                PrimaryButton(title: TodoSearchCopy.addAsTaskTitle(title), systemImage: "plus") {
                    router.present(.addTodoItem(prefill: title))
                }
                // One line with a middle truncation as designed, but the query must stay readable at large sizes.
                .lineLimit(typeSize.isAccessibilitySize ? 4 : 1)
                .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity)
        // Centered in the space below the field, as designed.
        .containerRelativeFrame(.vertical, alignment: .center)
    }
}

#if DEBUG
/// Builds the view model from in-memory collaborators and types the query, so each state is deterministic.
private struct TodoSearchPreviewHost: View {
    let query: String
    var recent: [String] = ["groceries", "dentist", "report"]
    @State private var viewModel: TodoSearchViewModel?
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if let viewModel { TodoSearchView(viewModel: viewModel, router: router, sortOrder: .default) }
        }
        .task {
            let dependencies = await PreviewDependencies.make(
                tasks: [
                    .init(title: "Buy groceries for the week", details: "Milk, eggs and bread", category: .shopping),
                    .init(title: "Plan grocery budget", category: .personal),
                    .init(title: "Grocery list sent to Sam", category: .personal, isCompleted: true),
                    .init(title: "Prepare quarterly report", category: .work),
                ],
                recentSearches: recent
            )
            let model = dependencies.makeTodoSearchViewModel()
            await model.load()
            await model.setQuery(query)
            viewModel = model
        }
    }
}

#Preview("Recent") { TodoSearchPreviewHost(query: "") }
#Preview("Results") { TodoSearchPreviewHost(query: "gro") }
#Preview("No results") { TodoSearchPreviewHost(query: "gym") }
#Preview("Accessibility3") { TodoSearchPreviewHost(query: "").dynamicTypeSize(.accessibility3) }
#Preview("Results - accessibility3") { TodoSearchPreviewHost(query: "gro").dynamicTypeSize(.accessibility3) }
#endif
