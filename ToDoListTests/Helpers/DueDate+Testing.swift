@testable import MyApp

/// Valid test dates only; production code must go through the throwing `DueDate` initializer.
func makeDueDate(_ year: Int, _ month: Int, _ day: Int) -> DueDate {
    try! DueDate(year: year, month: month, day: day)
}
