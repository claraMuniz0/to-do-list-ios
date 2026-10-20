import Foundation
import Observation

/// Quick date choices offered by the Select Date sheet.
enum QuickDate: Equatable {
    case today, tomorrow, nextWeek
}

/// State and intent of the Add Task form. Save is disabled (`canSave`) until the title has content,
/// so no validation error UI exists.
@MainActor @Observable
final class AddTodoItemViewModel {
    let categories = Category.defaults
    var details = ""
    var category: Category = .personal
    /// `nil` means no due date; it starts as today and the date sheet's Clear removes it.
    var dueDate: DueDate?
    private(set) var isSaving = false
    private(set) var saveFailed = false

    private var storedTitle: String
    private let addTodoItem: AddTodoItemUseCase
    private let dateProvider: DateProvider
    /// The injected calendar and clock, shared with the date sheet so it never reads `Calendar.current` or `.now`.
    let calendar: Calendar
    private let dueDateLabel: DueDateLabel

    init(
        addTodoItem: AddTodoItemUseCase,
        dateProvider: DateProvider,
        calendar: Calendar,
        locale: Locale = .current,
        initialTitle: String = ""
    ) {
        self.addTodoItem = addTodoItem
        self.dateProvider = dateProvider
        self.calendar = calendar
        dueDateLabel = DueDateLabel(dateProvider: dateProvider, calendar: calendar, locale: locale)
        storedTitle = String(initialTitle.prefix(TodoItemTitle.maxLength))
        dueDate = .today(using: dateProvider, calendar: calendar)
    }

    /// Typing past `TodoItemTitle.maxLength` is cut off rather than reported as an error.
    var title: String {
        get { storedTitle }
        set { storedTitle = String(newValue.prefix(TodoItemTitle.maxLength)) }
    }

    /// Also false while a save is running, which blocks a double submit.
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
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

    /// Returns whether the task was stored; a failure sets `saveFailed` and keeps the form editable.
    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await addTodoItem.execute(title: title, description: details, category: category, dueDate: dueDate)
            saveFailed = false
            return true
        } catch {
            saveFailed = true
            return false
        }
    }
}
