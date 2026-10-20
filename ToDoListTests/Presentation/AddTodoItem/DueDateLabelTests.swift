import Foundation
import Testing
@testable import MyApp

struct DueDateLabelTests {
    private let calendar = Calendar.utcGregorian
    private var label: DueDateLabel {
        DueDateLabel(
            dateProvider: DateProviderStub(current: calendar.makeDate(2026, 10, 8)),
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
    }

    @Test func todayIsPrefixedWithToday() {
        #expect(label.text(for: DueDate(year: 2026, month: 10, day: 8)) == "Today, Oct 8")
    }

    @Test func tomorrowIsPrefixedWithTomorrow() {
        #expect(label.text(for: DueDate(year: 2026, month: 10, day: 9)) == "Tomorrow, Oct 9")
    }

    @Test func otherDaysUseTheWeekday() {
        #expect(label.text(for: DueDate(year: 2026, month: 10, day: 13)) == "Tue, Oct 13")
    }

    @Test func pastDaysUseTheWeekday() {
        #expect(label.text(for: DueDate(year: 2026, month: 10, day: 7)) == "Wed, Oct 7")
    }

    @Test func tomorrowAcrossAMonthBoundary() {
        let endOfMonth = DueDateLabel(
            dateProvider: DateProviderStub(current: calendar.makeDate(2026, 10, 31)),
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(endOfMonth.text(for: DueDate(year: 2026, month: 11, day: 1)) == "Tomorrow, Nov 1")
    }

    @Test func noDateReadsNoDueDate() {
        #expect(label.text(for: nil) == "No due date")
    }
}
