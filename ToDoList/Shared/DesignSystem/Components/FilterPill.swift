import SwiftUI

/// Selection is conveyed by the `.isSelected` trait as well as color, so it does not rely on color alone.
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    /// Non-nil for a pill that toggles a panel (Categories): VoiceOver then hears Expanded/Collapsed instead of "selected".
    let isExpanded: Bool?
    let action: () -> Void

    init(title: String, isSelected: Bool = false, isExpanded: Bool? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.isExpanded = isExpanded
        self.action = action
    }

    /// Unselected outlines use the control border: the soft `border` is about 1.3:1 on white, below the 3:1 non-text minimum.
    static func borderColor(isSelected: Bool) -> Color { isSelected ? .clear : DSColor.borderControl }

    static func accessibilityValue(isExpanded: Bool?) -> String? {
        guard let isExpanded else { return nil }
        return isExpanded ? "Expanded" : "Collapsed"
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
                    Capsule().strokeBorder(Self.borderColor(isSelected: isSelected), lineWidth: 1)
                }
                .frame(minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected && isExpanded == nil ? .isSelected : [])
        .accessibilityValue(Self.accessibilityValue(isExpanded: isExpanded) ?? "")
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
