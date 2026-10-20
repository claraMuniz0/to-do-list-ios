import SwiftUI

struct AddTaskInput: View {
    @Binding var text: String
    let placeholder: String
    let onOptions: () -> Void
    let onAdd: () -> Void

    init(
        text: Binding<String>,
        placeholder: String = "Add a new task...",
        onOptions: @escaping () -> Void,
        onAdd: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onOptions = onOptions
        self.onAdd = onAdd
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField(
                "New task",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(DSColor.textMuted)
            )
            .dsFont(.inputText)
            .foregroundStyle(DSColor.textPrimary)
            .submitLabel(.done)
            .onSubmit(onAdd)

            Button(action: onOptions) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(width: DSTouchTarget.moreOptions, height: DSTouchTarget.moreOptions)
                    .frame(minWidth: DSTouchTarget.minimum, minHeight: DSTouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DSColor.onAccent)
                    .frame(width: DSTouchTarget.minimum, height: DSTouchTarget.minimum)
                    .background(DSColor.accent, in: Circle())
                    .dsShadow(.accentSmall)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add task")
        }
        .padding(.vertical, 8)
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(minHeight: DSTouchTarget.minimum + 16)
        .background(DSColor.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(DSColor.border, lineWidth: 1) }
        .dsShadow(.soft)
    }
}

#if DEBUG
private struct AddTaskInputPreviewHost: View {
    @State var text: String
    var body: some View {
        AddTaskInput(text: $text, onOptions: {}, onAdd: {}).padding()
    }
}

#Preview("Empty") { AddTaskInputPreviewHost(text: "") }
#Preview("With text") { AddTaskInputPreviewHost(text: "Call the dentist") }
#Preview("Long text") {
    AddTaskInputPreviewHost(text: "Renew the passport and book the appointment before the end of the month")
}
#Preview("Accessibility3") {
    AddTaskInputPreviewHost(text: "").dynamicTypeSize(.accessibility3)
}
#endif
