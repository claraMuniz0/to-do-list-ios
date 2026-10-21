import SwiftUI

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
                // The catcher goes before `.offset`: offset only moves the drawing, so an overlay added after it would stay
                // on the row's original frame and cover the revealed Delete button.
                .overlay { if isOpen { closeCatcher } }
                .offset(x: offset)
                .accessibilityAction(named: SwipeDeleteAction.accessibilityLabel(taskTitle: taskTitle), onDelete)
        }
        .simultaneousGesture(drag)
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isOpen)
    }

    private var closeCatcher: some View {
        Color.clear
            .contentShape(Rectangle())
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
