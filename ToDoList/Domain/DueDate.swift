import Foundation

enum DueDateError: Error, Equatable {
    case invalidDate
}

/// A proleptic Gregorian calendar day with no time component, so a time-zone change never shifts a saved date.
///
/// Past dates are valid: a saved task becomes overdue naturally and must still be editable.
/// The injected `Calendar` only supplies the time zone; the day itself is always Gregorian, so the
/// validation rules and the stored numbers do not depend on the user's calendar (Buddhist, Hebrew...).
///
/// - Throws: `DueDateError.invalidDate` for a year before 1, a month outside 1...12, or a day that does not
///   exist in that month (April 31, February 30, February 29 in a non-leap year).
struct DueDate: Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) throws {
        guard year >= 1, (1...12).contains(month), day >= 1, day <= Self.daysIn(month: month, year: year) else {
            throw DueDateError.invalidDate
        }
        self.init(validYear: year, month: month, day: day)
    }

    /// The day containing `date` in the calendar's time zone; always valid because it comes from a real date.
    init(_ date: Date, calendar: Calendar) {
        let components = Self.gregorian(matching: calendar).dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            preconditionFailure("A Gregorian calendar always yields year, month and day for a Date")
        }
        self.init(validYear: year, month: month, day: day)
    }

    private init(validYear year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
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
        let gregorian = Self.gregorian(matching: calendar)
        guard let date = gregorian.date(from: DateComponents(year: year, month: month, day: day)) else {
            preconditionFailure("A validated DueDate always maps to a real Gregorian date")
        }
        return date
    }

    static func < (lhs: DueDate, rhs: DueDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func shifted(byDays days: Int, using provider: DateProvider, calendar: Calendar) -> DueDate {
        guard let shifted = calendar.date(byAdding: .day, value: days, to: provider.now()) else {
            preconditionFailure("Adding whole days to a Date cannot fail")
        }
        return DueDate(shifted, calendar: calendar)
    }

    private static func gregorian(matching calendar: Calendar) -> Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        return gregorian
    }

    private static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 2: isLeap(year) ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    private static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
}
