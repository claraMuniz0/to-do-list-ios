import Foundation
@testable import MyApp

struct DateProviderStub: DateProvider {
    let current: Date

    func now() -> Date { current }
}
