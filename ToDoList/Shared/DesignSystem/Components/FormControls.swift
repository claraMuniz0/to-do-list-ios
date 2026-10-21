import SwiftUI

enum FormControlMetrics {
    static let singleLineMinHeight: CGFloat = 52
    static let textAreaMinHeight: CGFloat = 112
    static let dateRowMinHeight: CGFloat = 52
}

/// Border of a text control; the focused state uses the accent colour and a thicker line.
struct FormControlBorder: Equatable {
    let isFocused: Bool

    var usesAccent: Bool { isFocused }
    var lineWidth: CGFloat { isFocused ? 2 : 1 }
    var color: Color { isFocused ? DSColor.accent : DSColor.borderControl }
}

private struct FormControlChrome: ViewModifier {
    let isFocused: Bool
    let minHeight: CGFloat
    var onTap: (() -> Void)?

    func body(content: Content) -> some View {
        let border = FormControlBorder(isFocused: isFocused)
        let shape = RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
        
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(DSColor.surface, in: shape)
            .overlay { shape.strokeBorder(border.color, lineWidth: border.lineWidth) }
            // The whole box focuses the field, not just the text line.
            .contentShape(shape)
    }
}

/// Label above a control, with an optional "Optional" tag. The label is the accessibility
/// label of the whole group, so VoiceOver reads it before the control.
struct FormField<Content: View>: View {
    let label: String
    let isOptional: Bool
    let content: Content

    init(label: String, isOptional: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label
        self.isOptional = isOptional
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(label)
                    .dsFont(.chipOption)
                    .foregroundStyle(DSColor.textPrimary)
                if isOptional {
                    Text("Optional")
                        .dsFont(.chipTag)
                        .foregroundStyle(DSColor.textMuted)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isOptional ? "\(label), Optional" : label)
            .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Single-line text input. Focus is owned by the caller through `isFocused`; no length limit here.
struct TextInputField: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityLabel: String
    let isFocused: FocusState<Bool>.Binding?

    init(
        text: Binding<String>,
        placeholder: String = "e.g. Call the dentist",
        accessibilityLabel: String = "Task name",
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
        self.isFocused = isFocused
    }

    @FocusState private var internalFocus: Bool

    var body: some View {
        field
            .modifier(FormControlChrome(isFocused: focused, minHeight: FormControlMetrics.singleLineMinHeight, onTap: focus))
    }

    private func focus() {
        if let isFocused { isFocused.wrappedValue = true } else { internalFocus = true }
    }

    private var focused: Bool { isFocused?.wrappedValue ?? internalFocus }

    @ViewBuilder private var field: some View {
        let base = TextField(
            accessibilityLabel,
            text: $text,
            prompt: Text(placeholder).foregroundStyle(DSColor.textMuted)
        )
        .dsFont(.inputText)
        .foregroundStyle(DSColor.textPrimary)
        .submitLabel(.done)
        if let isFocused { base.focused(isFocused) } else { base.focused($internalFocus) }
    }
}

/// Multi-line text area (grows with its content).
struct TextAreaField: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityLabel: String

    init(
        text: Binding<String>,
        placeholder: String = "Add notes, links or any extra details...",
        accessibilityLabel: String = "Description"
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(
            accessibilityLabel,
            text: $text,
            prompt: Text(placeholder).foregroundStyle(DSColor.textMuted),
            axis: .vertical
        )
        .lineLimit(4...10)
        .dsFont(.inputText)
        .foregroundStyle(DSColor.textPrimary)
        .focused($isFocused)
        .modifier(FormControlChrome(isFocused: isFocused, minHeight: FormControlMetrics.textAreaMinHeight, onTap: { isFocused = true }))
    }
}

/// Calendar icon, value text and chevron in one button (e.g. "Today, Oct 8").
struct DateRow: View {
    let value: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var calendarSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var chevronSize: CGFloat = 14

    init(value: String, action: @escaping () -> Void) {
        self.value = value
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: calendarSize, weight: .regular))
                    .foregroundStyle(DSColor.accent)
                    .accessibilityHidden(true)
                Text(value)
                    .dsFont(.inputText)
                    .foregroundStyle(DSColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: chevronSize, weight: .semibold))
                    .foregroundStyle(DSColor.textMuted)
                    .accessibilityHidden(true)
            }
            .modifier(FormControlChrome(isFocused: false, minHeight: FormControlMetrics.dateRowMinHeight))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Due date")
        .accessibilityValue(value)
        .accessibilityHint("Opens the date picker")
    }
}

enum CircleIconButtonMetrics {
    static let diameter: CGFloat = DSTouchTarget.minimum
}

/// Circular icon-only button (e.g. Close). `accessibilityLabel` is required because there is no text.
struct CircleIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16
    private var diameter: CGFloat { max(CircleIconButtonMetrics.diameter, iconSize + 28) }

    init(systemImage: String = "xmark", accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(DSColor.textPrimary)
                .frame(width: diameter, height: diameter)
                .dsBackground(DSColor.surface, in: Circle(), shadow: .soft)
                .overlay { Circle().strokeBorder(DSColor.borderControl, lineWidth: 1) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
private struct FormPreviewHost: View {
    @State var title = ""
    @State var notes = ""
    @FocusState var focused: Bool
    let focusTitle: Bool
    var body: some View {
        VStack(spacing: 20) {
            FormField(label: "Task name") { TextInputField(text: $title, isFocused: $focused) }
            FormField(label: "Description", isOptional: true) { TextAreaField(text: $notes) }
            FormField(label: "Due date") { DateRow(value: "Today, Oct 8") {} }
        }
        .padding()
        .onAppear { focused = focusTitle }
    }
}

#Preview("Idle") { FormPreviewHost(focusTitle: false) }
#Preview("Title focused") { FormPreviewHost(focusTitle: true) }
#Preview("Filled") {
    FormPreviewHost(title: "Call the dentist", notes: "Ask about the Tuesday slot.\nBring insurance card.", focusTitle: false)
}
#Preview("Accessibility3") { FormPreviewHost(focusTitle: false).dynamicTypeSize(.accessibility3) }
#Preview("Circle icon button") { CircleIconButton(accessibilityLabel: "Close") {}.padding() }
#endif
