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

    @Test func celebrationHasSmallerDiscAndConfetti() {
        let layout = EmptyStateIllustrationLayout.celebration
        #expect(layout.canvas == 200)
        #expect(layout.halo == 200)
        #expect(layout.disc == 120)
        #expect(layout.symbolSize == 64)
        #expect(layout.dots.count == 7)
        #expect(layout.dots.filter { $0.barSize != nil }.count == 3)
    }

    @Test func celebrationBarsAreThinAndRotatedLikeTheDesign() {
        let bars = EmptyStateIllustrationLayout.celebration.dots.filter { $0.barSize != nil }
        #expect(bars.map(\.barSize) == [CGSize(width: 16, height: 6), CGSize(width: 16, height: 6), CGSize(width: 14, height: 6)])
        #expect(bars.map(\.rotation) == [30, -35, 20])
    }

    @Test func celebrationConfettiStaysInsideTheCanvas() {
        let layout = EmptyStateIllustrationLayout.celebration
        for piece in layout.dots {
            let size = piece.barSize ?? CGSize(width: piece.diameter, height: piece.diameter)
            #expect(piece.x >= 0 && piece.y >= 0)
            #expect(piece.x + size.width <= layout.canvas && piece.y + size.height <= layout.canvas)
        }
    }

    @Test func circularDotsHaveNoBarSize() {
        #expect(EmptyStateIllustrationLayout.welcome.dots.allSatisfy { $0.barSize == nil })
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
