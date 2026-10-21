import SwiftUI

/// The red action revealed behind a swiped row. The row, not this view, decides when it is visible to VoiceOver.
struct SwipeDeleteAction: View {
    static let title = "Delete"
    static let font = DSFont.swipeAction

    let action: () -> Void

    static func accessibilityLabel(taskTitle: String) -> String { "\(title) \(taskTitle)" }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                Text(Self.title).dsFont(Self.font)
            }
            .foregroundStyle(DSColor.onAccent)
            .frame(width: SwipeReveal.actionWidth)
            .frame(maxHeight: .infinity)
            .background(DSColor.danger, in: RoundedRectangle(cornerRadius: DSRadius.md))
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.md))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Default") { SwipeDeleteAction {}.frame(height: 78).padding() }
#Preview("Accessibility3") { SwipeDeleteAction {}.frame(height: 120).padding().dynamicTypeSize(.accessibility3) }
#endif
