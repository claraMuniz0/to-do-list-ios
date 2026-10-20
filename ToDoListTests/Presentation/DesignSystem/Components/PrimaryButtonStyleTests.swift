import Testing
@testable import MyApp

struct PrimaryButtonStyleTests {
    @Test func enabledIsOpaqueWithShadow() {
        #expect(PrimaryButtonAppearance(isEnabled: true).opacity == 1)
        #expect(PrimaryButtonAppearance(isEnabled: true).showsShadow)
    }

    @Test func disabledIsDimmedWithoutShadow() {
        #expect(PrimaryButtonAppearance(isEnabled: false).opacity == 0.4)
        #expect(PrimaryButtonAppearance(isEnabled: false).showsShadow == false)
    }
}
