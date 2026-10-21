import SwiftUI

/// Low-emphasis pill action (accent label on the soft accent fill) with a trailing chevron.
struct SoftPillButton: View {
    static let font = DSFont.softButton

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .dsFont(Self.font)
            .foregroundStyle(DSColor.accent)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(minHeight: DSTouchTarget.minimum)
            .background(DSColor.accentSoft, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Default") { SoftPillButton(title: "View completed (4)") {}.padding() }
#Preview("Accessibility3") { SoftPillButton(title: "View completed (4)") {}.padding().dynamicTypeSize(.accessibility3) }
#endif
