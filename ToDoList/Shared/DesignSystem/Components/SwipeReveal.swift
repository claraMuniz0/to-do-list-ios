import SwiftUI

/// Pure geometry of the swipe so the gesture rules are testable without a view.
enum SwipeReveal {
    /// The action is 80 wide plus an 8pt gap to the row.
    static let actionWidth: CGFloat = 80
    static let revealWidth: CGFloat = 88

    /// Row offset while dragging: follows the finger, clamped between closed and fully revealed.
    static func offset(startsOpen: Bool, translation: CGFloat) -> CGFloat {
        min(0, max(-revealWidth, (startsOpen ? -revealWidth : 0) + translation))
    }

    /// Where the row settles on release: open once it is past the halfway point.
    static func settlesOpen(startsOpen: Bool, translation: CGFloat) -> Bool {
        offset(startsOpen: startsOpen, translation: translation) <= -revealWidth / 2
    }

    /// Lets vertical scrolling win unless the drag is clearly sideways.
    static func isHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * 1.5
    }
}
