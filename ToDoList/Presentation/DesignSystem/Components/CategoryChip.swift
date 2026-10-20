import SwiftUI

/// Size and typography of a `CategoryChip`. `.tag` is the small list chip; `.option` is the
/// larger, selectable chip on the Add Task screen.
enum CategoryChipStyle: Equatable, CaseIterable {
    case tag, option

    var verticalPadding: CGFloat { self == .tag ? 4 : 10 }
    var horizontalPadding: CGFloat { self == .tag ? 10 : 16 }
    var font: DSFont { self == .tag ? .chipTag : .chipOption }
    /// Option chips always reserve the stroke so selecting one does not shift the layout.
    var selectionStrokeWidth: CGFloat { self == .tag ? 0 : 2 }
}

struct CategoryChip: View {
    let style: CategoryChipStyle
    let isSelected: Bool
    let label: String
    let palette: ChipPalette

    init(style: CategoryChipStyle = .tag, isSelected: Bool = false, label: String, palette: ChipPalette) {
        self.style = style
        self.isSelected = isSelected
        self.label = label
        self.palette = palette
    }

    var body: some View {
        Text(label)
            .dsFont(style.font)
            .foregroundStyle(palette.foreground)
            .padding(.vertical, style.verticalPadding)
            .padding(.horizontal, style.horizontalPadding)
            .background(palette.background, in: Capsule())
            .overlay {
                Capsule().strokeBorder(
                    isSelected ? DSColor.accent : Color.clear,
                    lineWidth: style.selectionStrokeWidth
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(style == .tag ? "Category: \(label)" : label)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("Tag - blue") { CategoryChip(style: .tag, label: "Work", palette: .blue).padding() }
#Preview("Tag - brick") { CategoryChip(style: .tag, label: "Personal", palette: .brick).padding() }
#Preview("Tag - green") { CategoryChip(style: .tag, label: "Shopping", palette: .green).padding() }
#Preview("Option - unselected") { CategoryChip(style: .option, label: "Work", palette: .blue).padding() }
#Preview("Option - selected") {
    CategoryChip(style: .option, isSelected: true, label: "Personal", palette: .brick).padding()
}
#Preview("Option - long label") {
    CategoryChip(style: .option, label: "Very long category name that wraps", palette: .green).padding()
}
#Preview("Option - accessibility3") {
    CategoryChip(style: .option, isSelected: true, label: "Shopping", palette: .green)
        .padding()
        .dynamicTypeSize(.accessibility3)
}
#endif
