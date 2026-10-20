import SwiftUI
import Testing
@testable import MyApp

struct EmptyStateIllustrationLayoutTests {
    @Test func welcomeMatchesDesign() {
        let layout = EmptyStateIllustrationLayout.welcome
        #expect(layout.canvas == 240)
        #expect(layout.halo == 200)
        #expect(layout.disc == 140)
        #expect(layout.symbolSize == 64)
        #expect(layout.dots.map(\.diameter) == [28, 18, 20, 12])
        #expect(layout.dots.map(\.color) == [.coral, .green, .peach, .blue])
    }

    @Test func celebrationHasSmallerDiscAndOneDot() {
        let layout = EmptyStateIllustrationLayout.celebration
        #expect(layout.canvas == 200)
        #expect(layout.halo == 200)
        #expect(layout.disc == 120)
        #expect(layout.symbolSize == 64)
        #expect(layout.dots.count == 1)
        #expect(layout.dots[0].color == .blue)
    }

    @Test func noResultsIsCompactWithTwoDots() {
        let layout = EmptyStateIllustrationLayout.noResults
        #expect(layout.canvas == 140)
        #expect(layout.disc == 90)
        #expect(layout.symbolSize == 48)
        #expect(layout.dots.map(\.color) == [.coral, .peach])
    }

    @Test(arguments: [EmptyStateIllustrationLayout.welcome, .celebration, .noResults])
    func everyDotStaysInsideTheCanvas(layout: EmptyStateIllustrationLayout) {
        for dot in layout.dots {
            #expect(dot.x >= 0 && dot.y >= 0)
            #expect(dot.x + dot.diameter <= layout.canvas)
            #expect(dot.y + dot.diameter <= layout.canvas)
        }
    }

    @Test func dotColorsResolveToTokens() {
        #expect(IllustrationDotColor.coral.color.lightHex == DSColor.accent.lightHex)
        #expect(IllustrationDotColor.green.color.lightHex == DSColor.illustrationGreen.lightHex)
        #expect(IllustrationDotColor.peach.color.lightHex == DSColor.illustrationPeach.lightHex)
        #expect(IllustrationDotColor.blue.color.lightHex == DSColor.illustrationBlue.lightHex)
    }
}
