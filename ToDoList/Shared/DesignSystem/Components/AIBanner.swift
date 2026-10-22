import SwiftUI

/// "Filled in by Claude" notice shown above a form Claude prefilled. Informational only, never tappable.
struct AIBanner: View {
    let message: String

    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 16

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: iconSize, weight: .semibold))
                .accessibilityHidden(true)
            Text(message).dsFont(.rowDescription)
        }
        .foregroundStyle(DSColor.accentText)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.accentSoft, in: RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Default") { AIBanner(message: "Filled in by Claude. Tap any field to adjust.").padding() }
#Preview("Accessibility3") {
    AIBanner(message: "Filled in by Claude. Tap any field to adjust.").padding().dynamicTypeSize(.accessibility3)
}
#endif
