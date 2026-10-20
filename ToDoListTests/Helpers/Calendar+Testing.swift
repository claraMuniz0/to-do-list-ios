import Foundation

extension Calendar {
    static let utcGregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    func makeDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
