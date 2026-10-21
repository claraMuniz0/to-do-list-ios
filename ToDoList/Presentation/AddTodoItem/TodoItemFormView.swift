import SwiftUI

/// Full-screen Add and Edit Task form. Renders the view model and forwards intent; holds no business logic.
struct TodoItemFormView: View {
    @Bindable var viewModel: TodoItemFormViewModel
    let onFinish: (TodoItemFormOutcome) -> Void

    @FocusState private var isTitleFocused: Bool
    @State private var isDateSheetPresented = false
    @State private var isEditFlow: Bool

    init(viewModel: TodoItemFormViewModel,
         onFinish: @escaping (TodoItemFormOutcome) -> Void,
         isEditFlow: Bool = false
    ) {
        self.viewModel = viewModel
        self.onFinish = onFinish
        self.isEditFlow = isEditFlow
    }

    private func close() { onFinish(.cancelled) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CircleIconButton(accessibilityLabel: "Close", action: close)
                    .accessibilityHint(viewModel.canDelete ? "Discards your changes" : "Discards the task")
                ScreenHeader(subtitle: viewModel.screenSubtitle, title: viewModel.screenTitle)
                
                FormField(label: "Task name") {
                    TextInputField(text: $viewModel.title, isFocused: $isTitleFocused)
                }
                
                FormField(label: "Description", isOptional: true) {
                    TextAreaField(text: $viewModel.details, accessibilityLabel: "Description, optional")
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
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .safeAreaInset(edge: .bottom) { saveBar }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
        .accessibilityAction(.escape, close)
        .task { await viewModel.load() }
        .onAppear {
            if !isEditFlow {
                isTitleFocused = true
            }
            
            AccessibilityNotification.ScreenChanged().post()
        }
        .onChange(of: viewModel.loadFailed) { _, failed in
            guard failed else { return }
            AccessibilityNotification.Announcement("Couldn't open the task.").post()
            close()
        }
        .sheet(isPresented: $isDateSheetPresented) {
            SelectDateView(viewModel: viewModel)
        }
    }

    private var categoryChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 8) { chips }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category")
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
                // The Button owns label and selected trait so VoiceOver does not read them twice.
                .accessibilityHidden(true)
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
            if viewModel.deleteFailed {
                Text("Couldn't delete the task. Try again.")
                    .dsFont(.rowDescription)
                    .foregroundStyle(DSColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear { AccessibilityNotification.Announcement("Couldn't delete the task. Try again.").post() }
            }
            if viewModel.canDelete {
                DestructiveTextButton(title: "Delete task", systemImage: "trash") {
                    Task { if let deleted = await viewModel.delete() { onFinish(.deleted(deleted)) } }
                }
            }
            PrimaryButton(title: viewModel.saveButtonTitle, systemImage: "checkmark", fullWidth: true, isEnabled: viewModel.canSave,
                          disabledHint: "Enter a task name first") {
                Task { if await viewModel.save() { onFinish(.saved) } }
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

extension TodoItem {
    /// Sample for the Edit previews (a Shopping task, so the real category shows as selected).
    static let previewGroceries = TodoItem(
        title: try! TodoItemTitle("Buy groceries for the week"),
        description: "Milk, eggs, bread and fruit. Don't forget the reusable bags!",
        category: .shopping,
        dueDate: try? DueDate(year: 2026, month: 10, day: 9),
        createdAt: Date(timeIntervalSince1970: 1_791_000_000)
    )
}

extension TodoItemFormViewModel {
    /// Deterministic, in-memory view model for previews.
    static func preview(
        title: String = "",
        details: String = "",
        failingSave: Bool = false,
        editing item: TodoItem? = nil
    ) -> TodoItemFormViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let provider = FixedDateProvider()
        let repository: TodoItemRepository = failingSave ? FailingRepository() : InMemoryTodoItemRepository()
        let viewModel = TodoItemFormViewModel(
            mode: item.map { .edit($0.id) } ?? .add,
            addTodoItem: AddTodoItemUseCase(repository: repository, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: repository),
            deleteTodoItem: DeleteTodoItemUseCase(repository: repository),
            getTodoItem: GetTodoItemUseCase(repository: repository),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
            initialTitle: title
        )
        viewModel.details = details
        if let item {
            Task {
                try? await repository.add(item)
                await viewModel.load()
            }
        }
        return viewModel
    }
}

#Preview("Empty") {
    TodoItemFormView(viewModel: .preview(), onFinish: { _ in })
}
#Preview("Filled") {
    TodoItemFormView(
        viewModel: .preview(title: "Call the dentist", details: "Ask about the Tuesday slot."),
        onFinish: { _ in }
    )
}
#Preview("Save disabled") {
    TodoItemFormView(viewModel: .preview(title: "   "), onFinish: { _ in })
}
#Preview("Save failed") {
    let viewModel = TodoItemFormViewModel.preview(title: "Call the dentist", failingSave: true)
    return TodoItemFormView(viewModel: viewModel, onFinish: { _ in })
        .task { _ = await viewModel.save() }
}
#Preview("Edit") {
    TodoItemFormView(
        viewModel: .preview(editing: .previewGroceries),
        onFinish: { _ in }
    )
}
#Preview("Edit - accessibility3") {
    TodoItemFormView(viewModel: .preview(editing: .previewGroceries), onFinish: { _ in })
        .dynamicTypeSize(.accessibility3)
}
#Preview("Accessibility3") {
    TodoItemFormView(viewModel: .preview(title: "Call the dentist"), onFinish: { _ in })
        .dynamicTypeSize(.accessibility3)
}
#endif
