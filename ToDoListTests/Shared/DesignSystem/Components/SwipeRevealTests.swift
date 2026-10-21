import CoreGraphics
import Testing
@testable import MyApp

struct SwipeRevealTests {
    @Test func revealWidthMatchesTheDesign() {
        #expect(SwipeReveal.revealWidth == 88)
        #expect(SwipeReveal.actionWidth == 80)
    }

    @Test func draggingLeftFromClosedFollowsTheFinger() {
        #expect(SwipeReveal.offset(startsOpen: false, translation: -30) == -30)
    }

    @Test func draggingRightFromClosedStaysClosed() {
        #expect(SwipeReveal.offset(startsOpen: false, translation: 40) == 0)
    }

    @Test func offsetNeverExceedsTheRevealWidth() {
        #expect(SwipeReveal.offset(startsOpen: false, translation: -300) == -88)
        #expect(SwipeReveal.offset(startsOpen: true, translation: -50) == -88)
    }

    @Test func draggingRightFromOpenClosesGradually() {
        #expect(SwipeReveal.offset(startsOpen: true, translation: 30) == -58)
        #expect(SwipeReveal.offset(startsOpen: true, translation: 200) == 0)
    }

    @Test func settlesOpenPastTheHalfwayPoint() {
        #expect(SwipeReveal.settlesOpen(startsOpen: false, translation: -45))
        #expect(!SwipeReveal.settlesOpen(startsOpen: false, translation: -43))
        #expect(SwipeReveal.settlesOpen(startsOpen: true, translation: 40))
        #expect(!SwipeReveal.settlesOpen(startsOpen: true, translation: 50))
    }

    @Test func aHorizontalDragWinsOnlyWhenClearlyHorizontal() {
        #expect(SwipeReveal.isHorizontal(CGSize(width: -30, height: 10)))
        #expect(!SwipeReveal.isHorizontal(CGSize(width: -10, height: 30)))
        #expect(!SwipeReveal.isHorizontal(CGSize(width: 20, height: 20)))
    }
}
