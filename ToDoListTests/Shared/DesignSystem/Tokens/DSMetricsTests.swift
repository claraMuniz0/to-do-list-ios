import SwiftUI
import Testing
@testable import MyApp

struct DSMetricsTests {
    @Test func radiiMatchDesign() {
        #expect(DSRadius.md == 16)
        #expect(DSRadius.pill == 999)
    }

    @Test func touchTargetsMatchDesign() {
        #expect(DSTouchTarget.minimum == 44)
        #expect(DSTouchTarget.moreOptions == 40)
        #expect(DSTouchTarget.checkboxRing == 26)
    }

    @Test func softShadowIsWarmAndOffsetThree() {
        #expect(DSShadow.soft.color.lightHex == "EAD6C3")
        #expect(DSShadow.soft.y == 3)
        #expect(DSShadow.soft.radius == 0)
    }

    @Test func accentShadowIsOffsetFourOnButtonsAndThreeOnAddButton() {
        #expect(DSShadow.accent.color.lightHex == "8F2A10")
        #expect(DSShadow.accent.y == 4)
        #expect(DSShadow.accentSmall.y == 3)
    }

    @Test func illustrationShadowHasBlur() {
        #expect(DSShadow.illustration.y == 8)
        #expect(DSShadow.illustration.radius == 24)
    }

    @Test func toastShadowIsTranslucentInk() {
        #expect(DSShadow.toast.y == 6)
        #expect(DSShadow.toast.radius == 20)
    }
}
