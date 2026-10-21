import SwiftUI

/// Submitting from the keyboard and tapping the plus both call `onAdd`; the caller must ignore empty text.
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var optionsIconSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var plusIconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var optionsFrame = DSTouchTarget.moreOptions
    private var plusSize: CGFloat { max(DSTouchTarget.minimum, plusIconSize + 24) }

    private var stacked: Bool { dynamicTypeSize.isAccessibilitySize }

    /// At accessibility sizes the field gets its own line above the buttons so the text stays readable.
    var body: some View {
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        let shape = stacked ? AnyShape(RoundedRectangle(cornerRadius: 28, style: .continuous)) : AnyShape(Capsule())
        
        layout {
            field
            
            if stacked {
                HStack(spacing: 8) { Spacer(minLength: 0); optionsButton; addButton }
            } else {
                optionsButton
                addButton
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(minHeight: DSTouchTarget.minimum + 16)
        .dsBackground(DSColor.surface, in: shape, shadow: .soft)
        .overlay {
            if stacked {
                RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DSColor.borderControl, lineWidth: 1)
            } else {
                Capsule().strokeBorder(DSColor.borderControl, lineWidth: 1)
            }
        }
    }

    private var field: some View {
        TextField(
                "New task",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(DSColor.textMuted)
            )
            .dsFont(.inputText)
            .foregroundStyle(DSColor.textPrimary)
            .submitLabel(.done)
            .onSubmit(onAdd)
    }

    private var optionsButton: some View {
        Button(action: onOptions) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: optionsIconSize, weight: .regular))
                .foregroundStyle(DSColor.textSecondary)
                .frame(width: optionsFrame, height: optionsFrame)
                .frame(minWidth: DSTouchTarget.minimum, minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More options")
    }

    private var addButton: some View {
        Button {
            if text.isEmpty {
                onOptions()
            } else {
                onAdd()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: plusIconSize, weight: .semibold))
                .foregroundStyle(DSColor.onAccent)
                .frame(width: plusSize, height: plusSize)
                .background(DSColor.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add task")
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
