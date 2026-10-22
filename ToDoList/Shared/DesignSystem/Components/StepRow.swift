import SwiftUI

/// Visual and spoken mapping for the two `StepRow` states (open and done). Pure so it can be unit tested.
struct StepRowStyle: Equatable {
    /// Design row height; the row grows with Dynamic Type.
    static let minRowHeight: CGFloat = 52
    /// Checkbox and grip keep their drawn size but get this tap area.
    static let hitArea: CGFloat = DSTouchTarget.minimum
    static let moveUpActionName = "Move up"
    static let moveDownActionName = "Move down"
    static let deleteActionName = "Delete step"
    static let textFieldLabel = "Edit step"

    /// A checkbox is named after its step; while the text is being retyped it falls back to a generic name
    /// so the button never has an empty label.
    static func checkboxLabel(for text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Step" : text
    }

    let isDone: Bool

    var textColor: Color { isDone ? DSColor.textMuted : DSColor.textPrimary }
    /// Same rule as `TaskRowStyle`: muted color carries the done state, no line-through.
    var strikesThroughText: Bool { false }
    var checkboxFill: Color { isDone ? DSColor.accent : DSColor.surface }
    var checkboxStroke: Color { isDone ? DSColor.accent : DSColor.border }
    var showsCheckmark: Bool { isDone }

    var accessibilityValue: String { isDone ? "Done" : "Not done" }
}

/// One editable step: leading checkbox, inline text field and a trailing grip. Reordering is exposed to
/// VoiceOver through `onMoveUp` / `onMoveDown` (the grip itself is decorative). The row never validates text:
/// `onSubmit` hands the typed text to the owner.
struct StepRow: View {
    @Binding var text: String
    let isDone: Bool
    let showsDivider: Bool
    let onToggle: () -> Void
    let onSubmit: (String) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        text: Binding<String>,
        isDone: Bool,
        showsDivider: Bool = true,
        onToggle: @escaping () -> Void,
        onSubmit: @escaping (String) -> Void = { _ in },
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self._text = text
        self.isDone = isDone
        self.showsDivider = showsDivider
        self.onToggle = onToggle
        self.onSubmit = onSubmit
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onDelete = onDelete
    }

    private var style: StepRowStyle { StepRowStyle(isDone: isDone) }

    @ScaledMetric(relativeTo: .body) private var checkboxSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var gripSize: CGFloat = 16
    private var hitSize: CGFloat { max(StepRowStyle.hitArea, checkboxSize + 20) }

    var body: some View {
        HStack(spacing: 4) {
            checkbox
            TextField(StepRowStyle.textFieldLabel, text: $text, axis: .vertical)
                .dsFont(.inputText)
                .foregroundStyle(style.textColor)
                .strikethrough(style.strikesThroughText)
                .submitLabel(.done)
                .onSubmit { onSubmit(text) }
                .frame(maxWidth: .infinity, alignment: .leading)
            grip
        }
        .padding(.vertical, 4)
        .frame(minHeight: StepRowStyle.minRowHeight)
        .overlay(alignment: .bottom) {
            if showsDivider { Rectangle().fill(DSColor.border).frame(height: 1) }
        }
        .accessibilityElement(children: .contain)
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(style.checkboxFill)
                    .overlay { Circle().strokeBorder(style.checkboxStroke, lineWidth: 2) }
                    .frame(width: checkboxSize, height: checkboxSize)
                if style.showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkmarkSize, weight: .bold))
                        .foregroundStyle(DSColor.onAccent)
                }
            }
            .frame(width: hitSize, height: hitSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The 44pt tap area is wider than the 24pt drawing; pull it back so the circle sits on the card padding.
        .padding(.leading, -(hitSize - checkboxSize) / 2)
        .accessibilityLabel(StepRowStyle.checkboxLabel(for: text))
        .accessibilityValue(style.accessibilityValue)
        // The row is a container, so its actions live on the checkbox, the one element VoiceOver focuses first.
        // Only the moves that are possible are offered.
        .accessibilityActions {
            if let onMoveUp { Button(StepRowStyle.moveUpActionName, action: onMoveUp) }
            if let onMoveDown { Button(StepRowStyle.moveDownActionName, action: onMoveDown) }
            if let onDelete { Button(StepRowStyle.deleteActionName, action: onDelete) }
        }
    }

    private var grip: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: gripSize, weight: .regular))
            .foregroundStyle(DSColor.textMuted)
            .frame(width: StepRowStyle.hitArea, height: StepRowStyle.hitArea)
            .padding(.trailing, -(StepRowStyle.hitArea - gripSize) / 2)
            .accessibilityHidden(true)
    }
}

#if DEBUG
private struct StepRowPreviewHost: View {
    @State var text: String
    let isDone: Bool
    var showsDivider = true

    var body: some View {
        StepRow(text: $text, isDone: isDone, showsDivider: showsDivider, onToggle: {})
            .padding(.horizontal, 18)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.md))
            .padding()
    }
}

#Preview("Open") { StepRowPreviewHost(text: "Book the flights", isDone: false) }
#Preview("Done") { StepRowPreviewHost(text: "Pick the dates", isDone: true) }
#Preview("Last, no divider") { StepRowPreviewHost(text: "Pack the bags", isDone: false, showsDivider: false) }
#Preview("Long text") {
    StepRowPreviewHost(text: "Compare the three cheapest flight options and check the baggage allowance", isDone: false)
}
#Preview("Accessibility3") {
    StepRowPreviewHost(text: "Book the flights", isDone: false).dynamicTypeSize(.accessibility3)
}
#endif
