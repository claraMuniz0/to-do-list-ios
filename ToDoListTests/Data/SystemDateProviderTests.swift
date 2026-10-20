import Foundation
import Testing
@testable import MyApp

struct SystemDateProviderTests {
    @Test func nowIsBetweenTwoBracketingReadings() {
        let before = Date()
        let reading = SystemDateProvider().now()
        let after = Date()
        #expect(before <= reading && reading <= after)
    }
}
