import SwiftUI

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(title: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .dsFont(.pill)
                .foregroundStyle(isSelected ? DSColor.onAccent : DSColor.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? DSColor.accent : DSColor.surface, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? Color.clear : DSColor.border, lineWidth: 1)
                }
                .frame(minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("Unselected") { FilterPill(title: "All") {}.padding() }
#Preview("Selected") { FilterPill(title: "Active", isSelected: true) {}.padding() }
#Preview("Row") {
    HStack {
        FilterPill(title: "All", isSelected: true) {}
        FilterPill(title: "Active") {}
        FilterPill(title: "Done") {}
    }
    .padding()
}
#Preview("Accessibility3") {
    FilterPill(title: "Next week", isSelected: true) {}
        .padding()
        .dynamicTypeSize(.accessibility3)
}
#endif
