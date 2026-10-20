import SwiftUI

/// The trash icon is fixed, so this toast only fits delete-undo. The "Undo" button's hint names the deleted task, which the host must restore.
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    private var icon: some View {
        Image(systemName: "trash")
            .font(.system(size: 18, weight: .regular))
            .accessibilityHidden(true)
    }

    private var messageText: some View {
        Text(message).dsFont(.toast)
    }

    private var undoButton: some View {
        Button(action: onUndo) {
            Text("Undo")
                .dsFont(.toast)
                .foregroundStyle(DSColor.toastAction)
                .frame(minWidth: DSTouchTarget.minimum, minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Undo")
        .accessibilityHint("Restores the deleted task")
    }

    /// Falls back to stacking the Undo button under the message when the text is too large for one line.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                icon
                messageText.frame(maxWidth: .infinity, alignment: .leading)
                undoButton
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 12) {
                    icon
                    messageText
                }
                undoButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(DSColor.onAccent)
        .padding(.vertical, 2)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .dsBackground(DSColor.toastBackground, in: RoundedRectangle(cornerRadius: DSRadius.md), shadow: .toast)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
#Preview("Default") { UndoToast(message: "Task deleted") {}.padding() }
#Preview("Long message") {
    UndoToast(message: "Task \"Call the landlord about the heating\" deleted") {}.padding()
}
#Preview("Accessibility3") { UndoToast(message: "Task deleted") {}.padding().dynamicTypeSize(.accessibility3) }
#endif
