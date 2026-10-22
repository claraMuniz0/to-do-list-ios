import CoreGraphics
import Testing
@testable import MyApp

struct SplashLayoutTests {
    private let layout = SplashLayout.design

    @Test func discAndCheckMatchDesign() {
        #expect(layout.disc == 168)
        #expect(layout.checkSize == 112)
        #expect(layout.checkSize < layout.disc)
    }

    @Test func ringSitsAboveTheDiscCenter() {
        #expect(layout.ring.diameter == 280)
        #expect(layout.ring.offset == CGSize(width: 0, height: -30))
        #expect(layout.ringLineWidth == 1.5)
    }

    @Test func glowIsALargeCircleTowardTheTopLeft() {
        #expect(layout.glow.diameter == 620)
        #expect(layout.glow.offset == CGSize(width: -25, height: -259))
    }

    @Test func dotsMatchDesign() {
        #expect(layout.dots.map(\.color) == [.cream, .soft, .dark])
        #expect(layout.dots.map(\.diameter) == [18, 12, 10])
        #expect(layout.dots.map(\.offset) == [
            CGSize(width: 114, height: -145),
            CGSize(width: -127, height: 107),
            CGSize(width: 132, height: 91),
        ])
    }

    @Test func dotsNeverTouchTheDisc() {
        for dot in layout.dots {
            let distance = hypot(dot.offset.width, dot.offset.height)
            #expect(distance > layout.disc / 2 + dot.diameter / 2)
        }
    }

    @Test func dotColorsResolveToTokens() {
        #expect(SplashDotColor.cream.color.lightHex == DSColor.splashCream.lightHex)
        #expect(SplashDotColor.soft.color.lightHex == DSColor.splashSoft.lightHex)
        #expect(SplashDotColor.dark.color.lightHex == DSColor.splashDark.lightHex)
    }
}
