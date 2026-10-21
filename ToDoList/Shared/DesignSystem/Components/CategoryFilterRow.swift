import SwiftUI

/// Selected state of a `CategoryFilterRow`. The border is thicker when selected, and the indicator
/// carries a check, so selection never relies on color alone.
struct CategoryFilterRowStyle: Equatable {
    let isSelected: Bool

    /// Unselected uses the control border for 3:1 contrast against the surface.
    var borderColor: Color { isSelected ? DSColor.accent : DSColor.borderControl }
    var borderWidth: CGFloat { isSelected ? 2 : 1 }
    var indicatorFill: Color { isSelected ? DSColor.accent : .clear }
    var indicatorStroke: Color { isSelected ? DSColor.accent : DSColor.textMuted }
    var showsCheckmark: Bool { isSelected }

    static func countLabel(_ count: Int) -> String {
        count == 1 ? "1 task" : "\(count) tasks"
    }

    static func accessibilityLabel(name: String, openCount: Int) -> String {
        "\(name), \(countLabel(openCount))"
    }
}

/// Radio-style row of the Categories panel: color dot, name, open-task count and a selection indicator.
struct CategoryFilterRow: View {
    let name: String
    let openCount: Int
    let palette: ChipPalette
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var indicatorSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 14

    var body: some View {
        let style = CategoryFilterRowStyle(isSelected: isSelected)
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(palette.foreground).frame(width: dotSize, height: dotSize)
                    .accessibilityHidden(true)
                Text(name)
                    .dsFont(.rowTitle)
                    .foregroundStyle(DSColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(CategoryFilterRowStyle.countLabel(openCount))
                    .dsFont(.count)
                    .foregroundStyle(DSColor.textSecondary)
                    .fixedSize()
                indicator(style)
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
            .frame(minHeight: DSTouchTarget.minimum)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay { RoundedRectangle(cornerRadius: DSRadius.md).strokeBorder(style.borderColor, lineWidth: style.borderWidth) }
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CategoryFilterRowStyle.accessibilityLabel(name: name, openCount: openCount))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func indicator(_ style: CategoryFilterRowStyle) -> some View {
        ZStack {
            Circle().fill(style.indicatorFill)
            Circle().strokeBorder(style.indicatorStroke, lineWidth: 2)
            if style.showsCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: checkmarkSize, weight: .bold))
                    .foregroundStyle(DSColor.onAccent)
            }
        }
        .frame(width: indicatorSize, height: indicatorSize)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Selected") { CategoryFilterRow(name: "Work", openCount: 2, palette: .blue, isSelected: true) {}.padding() }
#Preview("Unselected") { CategoryFilterRow(name: "Personal", openCount: 1, palette: .brick, isSelected: false) {}.padding() }
#Preview("Zero tasks") { CategoryFilterRow(name: "Shopping", openCount: 0, palette: .green, isSelected: false) {}.padding() }
#Preview("Long name") {
    CategoryFilterRow(name: "Home renovation and garden projects", openCount: 12, palette: .blue, isSelected: true) {}.padding()
}
#Preview("Accessibility3") {
    CategoryFilterRow(name: "Work", openCount: 2, palette: .blue, isSelected: true) {}.padding().dynamicTypeSize(.accessibility3)
}
#endif
