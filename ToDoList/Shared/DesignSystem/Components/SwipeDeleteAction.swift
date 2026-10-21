import SwiftUI

/// The red action revealed behind a swiped row. The row, not this view, decides when it is visible to VoiceOver.
struct SwipeDeleteAction: View {
    static let title = "Delete"
    static let font = DSFont.swipeAction

    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 22

    /// Includes the task title so the VoiceOver action stays unambiguous when several rows are listed in the rotor.
    static func accessibilityLabel(taskTitle: String) -> String { "\(title) \(taskTitle)" }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: iconSize))
                // The 80pt action cannot hold the label at accessibility sizes; the icon alone still reads, and the row has a spoken Delete action.
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(Self.title).dsFont(Self.font).lineLimit(1).minimumScaleFactor(0.8)
                }
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
