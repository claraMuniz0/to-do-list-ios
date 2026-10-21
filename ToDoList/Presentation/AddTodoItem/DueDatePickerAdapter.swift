import Foundation

/// Converts between the domain's `DueDate` and the `Date` the system DatePicker works with.
struct DueDatePickerAdapter {
    let calendar: Calendar
    /// Shown by the picker while no due date is set.
    let fallback: Date

    func date(for dueDate: DueDate?) -> Date {
        dueDate?.startOfDay(in: calendar) ?? fallback
    }

    func dueDate(from date: Date) -> DueDate {
        DueDate(date, calendar: calendar)
    }
}
