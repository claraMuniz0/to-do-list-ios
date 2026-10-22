import SwiftUI

/// Visual state of a `PrimaryButton`. The design does not define a disabled state (decision E3);
/// opacity 0.6 without shadow is the confirmed choice (0.4 was too faint to read).
struct PrimaryButtonAppearance: Equatable {
    let isEnabled: Bool

    var opacity: Double { isEnabled ? 1 : 0.6 }
    var showsShadow: Bool { isEnabled }
}

/// When `isEnabled` is false the button is dimmed, loses its shadow and ignores taps (it stays visible rather than hidden).
/// While `isLoading` a spinner replaces the icon and taps are ignored, without dimming.
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let fullWidth: Bool
    let isEnabled: Bool
    let isLoading: Bool
    let disabledHint: String?
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        fullWidth: Bool = false,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        disabledHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.fullWidth = fullWidth
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.disabledHint = disabledHint
        self.action = action
    }

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 18

    private var appearance: PrimaryButtonAppearance { PrimaryButtonAppearance(isEnabled: isEnabled) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(DSColor.onAccent).frame(width: iconSize, height: iconSize)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title).dsFont(.button)
            }
            .foregroundStyle(DSColor.onAccent)
            .padding(.vertical, 16)
            .padding(.horizontal, 28)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: DSTouchTarget.minimum)
            .dsBackground(DSColor.accent, in: Capsule(), shadow: appearance.showsShadow ? .accentSmall : .none)
            .opacity(appearance.opacity)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityValue(isLoading ? "Working" : "")
        .accessibilityHint(isEnabled ? "" : (disabledHint ?? ""))
    }
}

extension DSShadow {
    /// No-op shadow, used when a control drops its shadow (e.g. disabled button).
    static let none = DSShadow(color: .clear, radius: 0, y: 0)
}

#if DEBUG
#Preview("Default") { PrimaryButton(title: "Add task", systemImage: "plus") {}.padding() }
#Preview("No icon") { PrimaryButton(title: "Continue") {}.padding() }
#Preview("Full width") { PrimaryButton(title: "Save task", systemImage: "checkmark", fullWidth: true) {}.padding() }
#Preview("Disabled") {
    PrimaryButton(title: "Save task", systemImage: "checkmark", fullWidth: true, isEnabled: false) {}.padding()
}
#Preview("Long title - accessibility3") {
    PrimaryButton(title: "Add your first task", systemImage: "plus", fullWidth: true) {}
        .padding()
        .dynamicTypeSize(.accessibility3)
}
#endif
