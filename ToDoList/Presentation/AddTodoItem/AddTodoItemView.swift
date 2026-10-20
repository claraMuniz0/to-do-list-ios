import SwiftUI

/// Full-screen Add Task form. Renders the view model and forwards intent; holds no business logic.
struct AddTodoItemView: View {
    @Bindable var viewModel: AddTodoItemViewModel
    let onClose: () -> Void
    let onSaved: () -> Void

    @FocusState private var isTitleFocused: Bool
    @State private var isDateSheetPresented = false

    init(viewModel: AddTodoItemViewModel, onClose: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CircleIconButton(accessibilityLabel: "Close", action: onClose)
                ScreenHeader(subtitle: "What's on your mind?", title: "New task")
                FormField(label: "Task name") {
                    TextInputField(text: $viewModel.title, isFocused: $isTitleFocused)
                }
                FormField(label: "Description", isOptional: true) {
                    TextAreaField(text: $viewModel.details)
                }
                FormField(label: "Category") { categoryChips }
                FormField(label: "Due date") {
                    DateRow(value: viewModel.dueDateText) { isDateSheetPresented = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { saveBar }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
        .accessibilityAction(.escape, onClose)
        .onAppear { isTitleFocused = true }
        .sheet(isPresented: $isDateSheetPresented) {
            SelectDateSheet(viewModel: viewModel)
        }
    }

    private var categoryChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 8) { chips }
        }
    }

    private var chips: some View {
        ForEach(viewModel.categories, id: \.id) { category in
            Button { viewModel.category = category } label: {
                CategoryChip(
                    style: .option,
                    isSelected: viewModel.category == category,
                    label: category.name.value,
                    palette: ChipPalette(colorKey: category.color.key)
                )
                .frame(minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(category.name.value)
            .accessibilityAddTraits(viewModel.category == category ? .isSelected : [])
        }
    }

    private var saveBar: some View {
        VStack(spacing: 8) {
            if viewModel.saveFailed {
                Text("Couldn't save the task. Try again.")
                    .dsFont(.rowDescription)
                    .foregroundStyle(DSColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear { AccessibilityNotification.Announcement("Couldn't save the task. Try again.").post() }
            }
            PrimaryButton(title: "Save task", systemImage: "checkmark", fullWidth: true, isEnabled: viewModel.canSave) {
                Task { if await viewModel.save() { onSaved() } }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DSColor.bg)
    }
}

#if DEBUG
private struct FailingRepository: TodoItemRepository {
    struct Failure: Error {}
    func add(_ item: TodoItem) async throws { throw Failure() }
    func update(_ item: TodoItem) async throws { throw Failure() }
    func delete(id: TodoItemID) async throws { throw Failure() }
    func task(id: TodoItemID) async throws -> TodoItem? { nil }
    func allTasks() async throws -> [TodoItem] { [] }
}

private struct FixedDateProvider: DateProvider {
    func now() -> Date { Date(timeIntervalSince1970: 1_791_460_800) } // 2026-10-08 12:00 UTC
}

extension AddTodoItemViewModel {
    /// Deterministic, in-memory view model for previews.
    static func preview(
        title: String = "",
        details: String = "",
        failingSave: Bool = false
    ) -> AddTodoItemViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let provider = FixedDateProvider()
        let repository: TodoItemRepository = failingSave ? FailingRepository() : InMemoryTodoItemRepository()
        let viewModel = AddTodoItemViewModel(
            addTodoItem: AddTodoItemUseCase(repository: repository, dateProvider: provider, calendar: calendar),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
            initialTitle: title
        )
        viewModel.details = details
        return viewModel
    }
}

#Preview("Empty") {
    AddTodoItemView(viewModel: .preview(), onClose: {}, onSaved: {})
}
#Preview("Filled") {
    AddTodoItemView(
        viewModel: .preview(title: "Call the dentist", details: "Ask about the Tuesday slot."),
        onClose: {}, onSaved: {}
    )
}
#Preview("Save disabled") {
    AddTodoItemView(viewModel: .preview(title: "   "), onClose: {}, onSaved: {})
}
#Preview("Save failed") {
    let viewModel = AddTodoItemViewModel.preview(title: "Call the dentist", failingSave: true)
    return AddTodoItemView(viewModel: viewModel, onClose: {}, onSaved: {})
        .task { _ = await viewModel.save() }
}
#Preview("Accessibility3") {
    AddTodoItemView(viewModel: .preview(title: "Call the dentist"), onClose: {}, onSaved: {})
        .dynamicTypeSize(.accessibility3)
}
#endif
