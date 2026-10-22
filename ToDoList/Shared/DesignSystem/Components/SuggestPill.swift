import SwiftUI

/// Colors, state and spoken text of `SuggestPill`. Pure so it can be unit tested.
struct SuggestPillStyle: Equatable {
    static let fill = DSColor.accentSoft
    static let stroke = DSColor.accent
    static let foreground = DSColor.accent
    /// The pill is drawn 28pt tall; the tap area is padded up to this.
    static let minHitHeight: CGFloat = DSTouchTarget.minimum

    let isLoading: Bool

    var isDisabled: Bool { isLoading }
    var showsSpinner: Bool { isLoading }
    var iconName: String { "sparkles" }
    var accessibilityValue: String? { isLoading ? "Thinking of steps" : nil }
}

/// Accent pill that asks Claude for steps ("Suggest more", "Break it down"). While loading, a spinner
/// replaces the sparkle and the pill ignores taps. Callers hide it when Claude is unavailable.
struct SuggestPill: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .footnote) private var iconSize: CGFloat = 14

    private var style: SuggestPillStyle { SuggestPillStyle(isLoading: isLoading) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if style.showsSpinner {
                    ProgressView().controlSize(.mini).tint(SuggestPillStyle.foreground)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Image(systemName: style.iconName)
                        .font(.system(size: iconSize, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title).dsFont(.suggestPill)
            }
            .foregroundStyle(SuggestPillStyle.foreground)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(SuggestPillStyle.fill, in: Capsule())
            .overlay { Capsule().strokeBorder(SuggestPillStyle.stroke, lineWidth: 1) }
            .frame(minHeight: SuggestPillStyle.minHitHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(style.isDisabled)
        .accessibilityLabel(title)
        .accessibilityValue(style.accessibilityValue ?? "")
        .onChange(of: isLoading) { _, loading in
            if let message = SuggestPillStyle(isLoading: loading).accessibilityValue {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }
}

#if DEBUG
#Preview("Suggest more") { SuggestPill(title: "Suggest more", isLoading: false) {}.padding() }
#Preview("Break it down") { SuggestPill(title: "Break it down", isLoading: false) {}.padding() }
#Preview("Loading") { SuggestPill(title: "Suggest more", isLoading: true) {}.padding() }
#Preview("Accessibility3") {
    SuggestPill(title: "Suggest more", isLoading: false) {}.padding().dynamicTypeSize(.accessibility3)
}
#endif
