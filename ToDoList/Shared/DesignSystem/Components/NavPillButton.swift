import SwiftUI

/// Pill in a screen's top nav next to Close: "Manual" (outlined) and "Smart add" (accent-soft with an accent stroke).
/// Labels use `textPrimary` / `accentText`, both at least 4.5:1 on their fill; plain `accent` on accent-soft is 4.2:1.
struct NavPillButton: View {
    enum Style { case outlined, accent }

    let title: String
    let systemImage: String
    let style: Style
    var accessibilityHint: String?
    let action: () -> Void

    private var foreground: Color { style == .accent ? DSColor.accentText : DSColor.textPrimary }
    private var fill: Color { style == .accent ? DSColor.accentSoft : DSColor.surface }
    private var stroke: Color { style == .accent ? DSColor.accent : DSColor.border }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .dsFont(.softButton)
                .foregroundStyle(foreground)
                .padding(.horizontal, 16)
                .frame(minHeight: DSTouchTarget.minimum)
                .background(fill, in: Capsule())
                .overlay { Capsule().strokeBorder(stroke, lineWidth: 1) }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

#if DEBUG
#Preview("Manual") { NavPillButton(title: "Manual", systemImage: "pencil.line", style: .outlined) {}.padding() }
#Preview("Smart add") { NavPillButton(title: "Smart add", systemImage: "sparkles", style: .accent) {}.padding() }
#Preview("Accessibility3") {
    NavPillButton(title: "Smart add", systemImage: "sparkles", style: .accent) {}.padding().dynamicTypeSize(.accessibility3)
}
#endif
