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
        #expect(today == makeDueDate(2026, 10, 8))
    }

    @Test func tomorrowCrossesMonthBoundary() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 31))
        let tomorrow = DueDate.tomorrow(using: provider, calendar: calendar)
        #expect(tomorrow == makeDueDate(2026, 11, 1))
    }

    @Test func nextWeekIsSevenDaysAhead() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 12, 28))
        let nextWeek = DueDate.nextWeek(using: provider, calendar: calendar)
        #expect(nextWeek == makeDueDate(2027, 1, 4))
    }

    @Test(arguments: [
        (2027, 2, 28, 2027, 3, 1),
        (2028, 2, 28, 2028, 2, 29),
        (2026, 12, 31, 2027, 1, 1),
    ])
    func tomorrowHandlesMonthYearAndLeapBoundaries(y: Int, m: Int, d: Int, ey: Int, em: Int, ed: Int) {
        let provider = DateProviderStub(current: calendar.makeDate(y, m, d))
        #expect(DueDate.tomorrow(using: provider, calendar: calendar) == DueDate(year: ey, month: em, day: ed))
    }

    @Test func nextWeekCrossesMonthEnd() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 1, 28))
        #expect(DueDate.nextWeek(using: provider, calendar: calendar) == makeDueDate(2026, 2, 4))
    }

    @Test func lateEveningStillBelongsToToday() {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8, hour: 23))
        #expect(DueDate.today(using: provider, calendar: calendar) == makeDueDate(2026, 10, 8))
    }

    @Test func usesTheCalendarTimeZoneForTheDay() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let instant = calendar.makeDate(2026, 10, 8, hour: 20) // 05:00 on Oct 9 in Tokyo
        #expect(DueDate(instant, calendar: tokyo) == makeDueDate(2026, 10, 9))
        #expect(DueDate(instant, calendar: calendar) == makeDueDate(2026, 10, 8))
    }

    @Test func ordersChronologically() {
        #expect(makeDueDate(2026, 10, 8) < makeDueDate(2026, 10, 9))
        #expect(makeDueDate(2026, 12, 31) < makeDueDate(2027, 1, 1))
    }

    @Test func convertsBackToStartOfDay() {
        let dueDate = makeDueDate(2026, 10, 8)
        #expect(dueDate.startOfDay(in: calendar) == calendar.makeDate(2026, 10, 8, hour: 0))
    }

    // MARK: - Validation

    @Test func rejectsAMonthOutsideOneToTwelve() {
        for month in [-1, 0, 13] {
            #expect(throws: DueDateError.invalidDate) { try DueDate(year: 2026, month: month, day: 1) }
        }
    }

    @Test func rejectsADayThatDoesNotExistInTheMonth() {
        let impossible = [(2026, 4, 31), (2026, 2, 30), (2026, 2, 29), (2026, 1, 0), (2026, 1, 32), (2026, 6, -3)]
        for (year, month, day) in impossible {
            #expect(throws: DueDateError.invalidDate) { try DueDate(year: year, month: month, day: day) }
        }
    }

    @Test func rejectsAYearBeforeOne() {
        #expect(throws: DueDateError.invalidDate) { try DueDate(year: 0, month: 1, day: 1) }
    }

    @Test func acceptsTheLeapDayOnlyInLeapYears() throws {
        #expect(try DueDate(year: 2028, month: 2, day: 29).day == 29)
        #expect(try DueDate(year: 2000, month: 2, day: 29).day == 29)
        #expect(throws: DueDateError.invalidDate) { try DueDate(year: 2100, month: 2, day: 29) }
    }

    @Test func acceptsTheFirstAndLastDayOfEveryMonth() throws {
        let lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        for (index, length) in lengths.enumerated() {
            _ = try DueDate(year: 2026, month: index + 1, day: 1)
            _ = try DueDate(year: 2026, month: index + 1, day: length)
        }
    }

    @Test func aDayFromARealDateIsAlwaysValidEvenWithANonGregorianCalendar() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Calendar.utcGregorian.makeDate(2026, 10, 8, hour: 0)

        let due = DueDate(date, calendar: buddhist)

        #expect(due == makeDueDate(2026, 10, 8))
        #expect(due.startOfDay(in: buddhist) == date)
    }
}
