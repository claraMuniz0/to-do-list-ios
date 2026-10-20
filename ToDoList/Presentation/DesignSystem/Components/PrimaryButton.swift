import SwiftUI

/// Visual state of a `PrimaryButton`. The design does not define a disabled state yet;
/// opacity 0.4 without shadow is the confirmed Phase 1 choice.
struct PrimaryButtonAppearance: Equatable {
    let isEnabled: Bool

    var opacity: Double { isEnabled ? 1 : 0.6 }
    var showsShadow: Bool { isEnabled }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let fullWidth: Bool
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        fullWidth: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.fullWidth = fullWidth
        self.isEnabled = isEnabled
        self.action = action
    }

    private var appearance: PrimaryButtonAppearance { PrimaryButtonAppearance(isEnabled: isEnabled) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
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
        .disabled(!isEnabled)
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
