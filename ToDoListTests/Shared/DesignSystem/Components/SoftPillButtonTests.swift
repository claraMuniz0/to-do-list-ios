import Testing
@testable import MyApp

struct SoftPillButtonTests {
    @Test func labelUsesTheSoftButtonToken() {
        #expect(SoftPillButton.font == .softButton)
        #expect(DSFont.softButton.spec.family == "Outfit")
        #expect(DSFont.softButton.spec.size == 15)
        #expect(DSFont.softButton.spec.weight == .semibold)
        #expect(DSFont.softButton.spec.textStyle != nil)
    }
}
