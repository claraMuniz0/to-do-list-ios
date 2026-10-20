import SwiftUI

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .regular))
                .accessibilityHidden(true)
            Text(message)
                .dsFont(.toast)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .foregroundStyle(DSColor.onAccent)
        .padding(.vertical, 2)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .background(DSColor.toastBackground, in: RoundedRectangle(cornerRadius: DSRadius.md))
        .dsShadow(.toast)
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
