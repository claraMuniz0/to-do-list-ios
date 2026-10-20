import SwiftUI

struct TodoListErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Couldn't load your tasks")
                .dsFont(.emptyTitle)
                .foregroundStyle(DSColor.textPrimary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Retry", systemImage: "arrow.clockwise", action: onRetry)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.bg.ignoresSafeArea())
    }
}

#if DEBUG
#Preview("Error") { TodoListErrorView {} }
#Preview("Error - accessibility3") { TodoListErrorView {}.dynamicTypeSize(.accessibility3) }
#endif
