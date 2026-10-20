import Foundation

/// Turns a `DueDate` into the form's label: "Today, Oct 8", "Tomorrow, Oct 9", "Tue, Oct 13".
/// Presentation-only, so Domain never formats text.
struct DueDateLabel {
    let dateProvider: DateProvider
    let calendar: Calendar
    var locale: Locale = .current

    func text(for dueDate: DueDate?) -> String {
        guard let dueDate else { return "No due date" }
        let day = formatted(dueDate, template: "MMMd")
        if dueDate == .today(using: dateProvider, calendar: calendar) { return "Today, \(day)" }
        if dueDate == .tomorrow(using: dateProvider, calendar: calendar) { return "Tomorrow, \(day)" }
        return formatted(dueDate, template: "EEEMMMd")
    }

    private func formatted(_ dueDate: DueDate, template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: dueDate.startOfDay(in: calendar))
    }
}
