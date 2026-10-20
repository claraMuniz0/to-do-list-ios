import Foundation
import Testing
@testable import MyApp

struct DueDatePickerAdapterTests {
    private let calendar = Calendar.utcGregorian
    private var fallback: Date { calendar.makeDate(2026, 10, 8, hour: 9) }
    private var sut: DueDatePickerAdapter { DueDatePickerAdapter(calendar: calendar, fallback: fallback) }

    @Test func convertsADueDateToItsStartOfDay() {
        let date = sut.date(for: DueDate(year: 2026, month: 10, day: 20))
        #expect(date == calendar.makeDate(2026, 10, 20, hour: 0))
    }

    @Test func showsTheFallbackWhenThereIsNoDueDate() {
        #expect(sut.date(for: nil) == fallback)
    }

    @Test func convertsAPickedDateIgnoringTheTimeOfDay() {
        #expect(sut.dueDate(from: calendar.makeDate(2026, 12, 31, hour: 23)) == DueDate(year: 2026, month: 12, day: 31))
    }

    @Test func roundTripsAcrossAMonthBoundary() {
        let due = DueDate(year: 2027, month: 1, day: 1)
        #expect(sut.dueDate(from: sut.date(for: due)) == due)
    }
}
