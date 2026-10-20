import Testing
@testable import MyApp

struct DSControlBorderTests {
    @Test func controlBorderIsDarkerThanSoftBorder() {
        #expect(DSColor.borderControl.lightHex == "8E8272")
        #expect(DSColor.borderControl.lightHex != DSColor.border.lightHex)
    }
}
