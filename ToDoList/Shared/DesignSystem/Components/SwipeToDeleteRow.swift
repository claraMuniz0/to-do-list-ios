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

/// Wraps any row with swipe-left-to-delete. Opening is controlled by the host so only one row is open at a time;
/// tapping the open row closes it instead of triggering the row's own tap.
struct SwipeToDeleteRow<Content: View>: View {
    let isOpen: Bool
    let taskTitle: String
    let onOpenChange: (Bool) -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var dragTranslation: CGFloat?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var offset: CGFloat {
        SwipeReveal.offset(startsOpen: isOpen, translation: dragTranslation ?? 0)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            SwipeDeleteAction(action: onDelete)
                .opacity(offset < 0 ? 1 : 0)
                .accessibilityHidden(true)
            content
                .dsShadow(offset < 0 ? .swipedRow : .none)
                .offset(x: offset)
                .overlay { if isOpen { closeCatcher } }
                .accessibilityAction(named: SwipeDeleteAction.accessibilityLabel(taskTitle: taskTitle), onDelete)
        }
        .simultaneousGesture(drag)
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isOpen)
    }

    private var closeCatcher: some View {
        Color.clear
            .contentShape(Rectangle())
            .offset(x: offset)
            .onTapGesture { onOpenChange(false) }
            .accessibilityHidden(true)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard SwipeReveal.isHorizontal(value.translation) else {
                    if isOpen, abs(value.translation.height) > 12 { onOpenChange(false) }
                    return
                }
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                defer { dragTranslation = nil }
                guard SwipeReveal.isHorizontal(value.translation) else { return }
                onOpenChange(SwipeReveal.settlesOpen(startsOpen: isOpen, translation: value.translation.width))
            }
    }
}

#if DEBUG
#Preview("Closed") {
    SwipeToDeleteRow(isOpen: false, taskTitle: "Finish report", onOpenChange: { _ in }, onDelete: {}) {
        TaskRow(title: "Finish quarterly report", categoryName: "Work", palette: .blue) {}
    }.padding()
}
#Preview("Open") {
    SwipeToDeleteRow(isOpen: true, taskTitle: "Finish report", onOpenChange: { _ in }, onDelete: {}) {
        TaskRow(title: "Finish quarterly report", categoryName: "Work", palette: .blue) {}
    }.padding()
}
#endif
