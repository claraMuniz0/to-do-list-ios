import Foundation
import Testing
@testable import MyApp

struct DueDateTests {
    private let calendar = Calendar.utcGregorian

    @Test func keepsOnlyTheCalendarDay() {
        let morning = DueDate(calendar.makeDate(2026, 10, 8, hour: 1), calendar: calendar)
        let night = DueDate(calendar.makeDate(2026, 10, 8, hour: 23), calendar: calendar)
        #expect(morning == night)
    }

    @Test func todayUsesTheProvider() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8))
        let today = DueDate.today(using: provider, calendar: calendar)
        #expect(today == DueDate(year: 2026, month: 10, day: 8))
    }

    @Test func tomorrowCrossesMonthBoundary() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 31))
        let tomorrow = DueDate.tomorrow(using: provider, calendar: calendar)
        #expect(tomorrow == DueDate(year: 2026, month: 11, day: 1))
    }

    @Test func nextWeekIsSevenDaysAhead() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 12, 28))
        let nextWeek = DueDate.nextWeek(using: provider, calendar: calendar)
        #expect(nextWeek == DueDate(year: 2027, month: 1, day: 4))
    }

    @Test func ordersChronologically() {
        #expect(DueDate(year: 2026, month: 10, day: 8) < DueDate(year: 2026, month: 10, day: 9))
        #expect(DueDate(year: 2026, month: 12, day: 31) < DueDate(year: 2027, month: 1, day: 1))
    }

    @Test func convertsBackToStartOfDay() {
        let dueDate = DueDate(year: 2026, month: 10, day: 8)
        #expect(dueDate.startOfDay(in: calendar) == calendar.makeDate(2026, 10, 8, hour: 0))
    }
}
