import SwiftUI

/// The Smart add text card: sparkle and label on top, the sentence, and a "n / 280" counter. Focus is owned by the caller.
struct SmartInputField: View {
    @Binding var text: String
    let label: String
    let placeholder: String
    let counterText: String
    let spokenCounterText: String
    let isFocused: FocusState<Bool>.Binding

    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 16

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
        let border = FormControlBorder(isFocused: isFocused.wrappedValue)
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
                    .accessibilityHidden(true)
                Text(label).dsFont(.chipOption).foregroundStyle(DSColor.textSecondary)
            }
            .accessibilityHidden(true)
            TextField(label, text: $text, prompt: Text(placeholder).foregroundStyle(DSColor.textMuted), axis: .vertical)
                .lineLimit(3...8)
                .dsFont(.smartInput)
                .foregroundStyle(DSColor.textPrimary)
                .focused(isFocused)
            Text(counterText)
                .dsFont(.count)
                .foregroundStyle(DSColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(spokenCounterText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(DSColor.surface, in: shape)
        .overlay { shape.strokeBorder(border.color, lineWidth: border.lineWidth) }
        .contentShape(shape)
        .onTapGesture { isFocused.wrappedValue = true }
    }
}

#if DEBUG
private struct SmartInputPreviewHost: View {
    @State var text: String
    @FocusState private var focused: Bool
    var body: some View {
        SmartInputField(
            text: $text, label: "Describe your task", placeholder: "e.g. Dentist next Tuesday at 3pm",
            counterText: "\(text.count) / 280", spokenCounterText: "\(text.count) of 280 characters", isFocused: $focused
        )
        .padding()
    }
}
#Preview("Empty") { SmartInputPreviewHost(text: "") }
#Preview("Filled") { SmartInputPreviewHost(text: "Dentist next Tuesday at 3pm, high priority. Bring insurance card.") }
#Preview("Accessibility3") { SmartInputPreviewHost(text: "Dentist next Tuesday").dynamicTypeSize(.accessibility3) }
#endif
