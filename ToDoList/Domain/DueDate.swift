import Foundation

/// A calendar day with no time component, so a time-zone change never shifts a saved date.
///
/// Past dates are valid: a saved task becomes overdue naturally and must still be editable.
struct DueDate: Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 0, month: components.month ?? 1, day: components.day ?? 1)
    }

    static func today(using provider: DateProvider, calendar: Calendar) -> DueDate {
        DueDate(provider.now(), calendar: calendar)
    }

    static func tomorrow(using provider: DateProvider, calendar: Calendar) -> DueDate {
        shifted(byDays: 1, using: provider, calendar: calendar)
    }

    /// Today plus 7 days, not "next Monday", so the label is unambiguous.
    static func nextWeek(using provider: DateProvider, calendar: Calendar) -> DueDate {
        shifted(byDays: 7, using: provider, calendar: calendar)
    }

    func startOfDay(in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    static func < (lhs: DueDate, rhs: DueDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func shifted(byDays days: Int, using provider: DateProvider, calendar: Calendar) -> DueDate {
        let shifted = calendar.date(byAdding: .day, value: days, to: provider.now()) ?? provider.now()
        return DueDate(shifted, calendar: calendar)
    }
}
