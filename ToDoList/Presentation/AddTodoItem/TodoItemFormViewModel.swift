import Foundation
import Observation

/// Quick date choices offered by the Select Date sheet.
enum QuickDate: Equatable {
    case today, tomorrow, nextWeek
}

/// State and intent of the Add and Edit Task form. Save is disabled (`canSave`) until the title has content,
/// so no validation error UI exists.
@MainActor @Observable
final class TodoItemFormViewModel {
    let categories = Category.defaults
    var details = ""
    var category: Category = .personal
    /// `nil` means no due date. Add mode starts as today; edit mode starts empty until `load()` fills it. The date sheet's Clear removes it.
    var dueDate: DueDate?
    /// The steps being edited; they reach the store only when `save()` succeeds.
    private(set) var stepList = StepList()
    private(set) var isSaving = false
    private(set) var saveFailed = false
    /// Set when `delete()` failed; the task is still stored and the form stays open so the user can retry.
    private(set) var deleteFailed = false
    /// Set when the item being edited could not be loaded; the view reports it and closes.
    private(set) var loadFailed = false

    let mode: TodoItemFormMode
    private var storedTitle: String
    private let addTodoItem: AddTodoItemUseCase
    private let updateTodoItem: UpdateTodoItemUseCase
    private let deleteTodoItem: DeleteTodoItemUseCase
    private let getTodoItem: GetTodoItemUseCase
    private let dateProvider: DateProvider
    /// The injected calendar and clock, shared with the date sheet so it never reads `Calendar.current` or `.now`.
    let calendar: Calendar
    private let dueDateLabel: DueDateLabel

    init(
        mode: TodoItemFormMode = .add,
        addTodoItem: AddTodoItemUseCase,
        updateTodoItem: UpdateTodoItemUseCase,
        deleteTodoItem: DeleteTodoItemUseCase,
        getTodoItem: GetTodoItemUseCase,
        dateProvider: DateProvider,
        calendar: Calendar,
        locale: Locale = .current,
        initialTitle: String = ""
    ) {
        self.mode = mode
        self.addTodoItem = addTodoItem
        self.updateTodoItem = updateTodoItem
        self.deleteTodoItem = deleteTodoItem
        self.getTodoItem = getTodoItem
        self.dateProvider = dateProvider
        self.calendar = calendar
        dueDateLabel = DueDateLabel(dateProvider: dateProvider, calendar: calendar, locale: locale)
        storedTitle = String(initialTitle.prefix(TodoItemTitle.maxLength))
        dueDate = mode == .add ? .today(using: dateProvider, calendar: calendar) : nil
    }

    var screenSubtitle: String { editingID == nil ? "What's on your mind?" : "Make it just right" }
    var screenTitle: String { editingID == nil ? "New task" : "Edit task" }
    var saveButtonTitle: String { editingID == nil ? "Save task" : "Save changes" }
    var canDelete: Bool { editingID != nil }

    private var editingID: TodoItemID? {
        if case .edit(let id) = mode { return id }
        return nil
    }

    /// Prefills the form in edit mode, keeping a past or missing due date as stored; does nothing in add mode.
    func load() async {
        guard let id = editingID else { return }
        do {
            let item = try await getTodoItem.execute(id: id)
            title = item.title.value
            details = item.description ?? ""
            category = item.category
            dueDate = item.dueDate
            stepList = StepList(item.steps)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    /// Typing past `TodoItemTitle.maxLength` is cut off rather than reported as an error.
    var title: String {
        get { storedTitle }
        set { storedTitle = String(newValue.prefix(TodoItemTitle.maxLength)) }
    }

    /// Also false while a save or delete is running, which blocks a double submit.
    var canSave: Bool {
        !TodoItemTitle.isBlank(title) && !isSaving
    }

    var dueDateText: String { dueDateLabel.text(for: dueDate) }

    var now: Date { dateProvider.now() }

    /// New dates start today; an already-chosen earlier date stays reachable so it is not silently moved.
    var earliestSelectableDueDate: DueDate {
        let today = DueDate.today(using: dateProvider, calendar: calendar)
        guard let dueDate else { return today }
        return min(today, dueDate)
    }

    var selectedQuickDate: QuickDate? {
        guard let dueDate else { return nil }
        if dueDate == .today(using: dateProvider, calendar: calendar) { return .today }
        if dueDate == .tomorrow(using: dateProvider, calendar: calendar) { return .tomorrow }
        if dueDate == .nextWeek(using: dateProvider, calendar: calendar) { return .nextWeek }
        return nil
    }

    func selectToday() { dueDate = .today(using: dateProvider, calendar: calendar) }
    func selectTomorrow() { dueDate = .tomorrow(using: dateProvider, calendar: calendar) }
    func selectNextWeek() { dueDate = .nextWeek(using: dateProvider, calendar: calendar) }
    func clearDueDate() { dueDate = nil }

    // MARK: - Steps

    /// Add has no Steps field in the design; steps are added once the task exists.
    var showsSteps: Bool { editingID != nil }
    var steps: [Step] { stepList.steps }
    var stepsProgress: StepsProgress? { stepList.progress }
    var canAddStep: Bool { stepList.steps.count < StepList.maxSteps }

    /// Replaces the whole draft, for a Claude suggestion the user accepted.
    func setSteps(_ newList: StepList) { stepList = newList }

    /// Returns whether a step was added: blank or overlong text and a full list are rejected, not reported as errors.
    @discardableResult
    func addStep(_ text: String) -> Bool {
        guard let title = try? StepTitle(text) else { return false }
        return (try? stepList.add(title)) != nil
    }

    func toggleStep(_ id: StepID) { try? stepList.toggle(id) }
    func removeStep(_ id: StepID) { try? stepList.remove(id) }
    func moveStep(from source: Int, to destination: Int) { try? stepList.move(from: source, to: destination) }

    /// Returns whether the title changed; blank or overlong text keeps the old title.
    @discardableResult
    func renameStep(_ id: StepID, to text: String) -> Bool {
        guard let title = try? StepTitle(text) else { return false }
        return (try? stepList.rename(id, to: title)) != nil
    }

    /// Returns whether the task was stored; a failure sets `saveFailed` and keeps the form editable.
    /// In edit mode a task deleted elsewhere since `load()` also lands here (`notFound`), not as a separate error.
    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            if let id = editingID {
                try await updateTodoItem.execute(
                    id: id, title: title, description: details, category: category, dueDate: dueDate, steps: stepList
                )
            } else {
                try await addTodoItem.execute(title: title, description: details, category: category, dueDate: dueDate)
            }
            saveFailed = false
            return true
        } catch {
            saveFailed = true
            return false
        }
    }

    /// Returns the deleted item so the list can offer Undo; nil in add mode or when the delete failed (`deleteFailed`).
    func delete() async -> TodoItem? {
        guard let id = editingID, !isSaving else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            let item = try await deleteTodoItem.execute(id: id)
            deleteFailed = false
            return item
        } catch {
            deleteFailed = true
            return nil
        }
    }
}
