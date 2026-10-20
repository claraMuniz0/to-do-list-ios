import Foundation

struct SystemDateProvider: DateProvider {
    func now() -> Date { Date() }
}
