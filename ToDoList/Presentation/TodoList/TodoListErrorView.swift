import SwiftUI

struct TodoListErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    Text("Couldn't load your tasks")
                        .dsFont(.emptyTitle)
                        .foregroundStyle(DSColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    PrimaryButton(title: "Retry", systemImage: "arrow.clockwise", action: onRetry)
                }
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .background(DSColor.bg.ignoresSafeArea())
        .onAppear { AccessibilityNotification.Announcement("Couldn't load your tasks").post() }
    }
}

#if DEBUG
#Preview("Error") { TodoListErrorView {} }
#Preview("Error - accessibility3") { TodoListErrorView {}.dynamicTypeSize(.accessibility3) }
#endif
