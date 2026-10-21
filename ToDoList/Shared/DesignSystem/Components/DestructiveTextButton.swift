import SwiftUI

/// A text button for destructive actions such as "Delete task". It has no confirmation of its own;
/// the host decides whether to confirm. The design draws the label at 16pt; this uses the 17pt `.button` token.
struct DestructiveTextButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 18

    var body: some View {
        Button(role: .destructive, action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .regular))
                    .accessibilityHidden(true)
                Text(title).dsFont(.button)
            }
            .foregroundStyle(DSColor.danger)
            .frame(maxWidth: .infinity, minHeight: DSTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Default") { DestructiveTextButton(title: "Delete task", systemImage: "trash") {}.padding() }
#Preview("Accessibility3") {
    DestructiveTextButton(title: "Delete task", systemImage: "trash") {}
        .padding()
        .dynamicTypeSize(.accessibility3)
}
#endif
