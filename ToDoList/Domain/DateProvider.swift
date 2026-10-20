import Foundation

/// The only way Domain reads the current time, so "Today" and "Tomorrow" are testable.
/// Not named `Clock`, which Swift already defines.
protocol DateProvider {
    func now() -> Date
}
