import SwiftUI

/// Shown whenever there are zero tasks. The button is pinned; the content scrolls at large Dynamic Type.
struct WelcomeView: View {
    let onAddFirstTask: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ScreenHeader(subtitle: "Welcome 👋", title: "My Tasks")
                VStack(spacing: 24) {
                    EmptyStateIllustration(symbol: "list.clipboard")
                    VStack(spacing: 12) {
                        Text("Nothing to do yet")
                            .dsFont(.emptyTitle)
                            .foregroundStyle(DSColor.textPrimary)
                        Text("Add your first task, then tap the circle whenever it's done.")
                            .dsFont(.inputText)
                            .foregroundStyle(DSColor.textSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: 290)
                    }
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Add your first task", systemImage: "plus", fullWidth: true, action: onAddFirstTask)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
    }
}

#if DEBUG
#Preview("Empty") { WelcomeView {} }
#Preview("Empty - accessibility3") { WelcomeView {}.dynamicTypeSize(.accessibility3) }
#endif
