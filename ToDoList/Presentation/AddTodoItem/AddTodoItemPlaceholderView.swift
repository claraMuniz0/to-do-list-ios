import SwiftUI

/// Stand-in until the Add Task form lands in Phase 3.
struct AddTodoItemPlaceholderView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ScreenHeader(subtitle: "What's on your mind?", title: "New task")
            Spacer()
            PrimaryButton(title: "Close", fullWidth: true, action: onClose)
        }
        .padding(20)
        .background(DSColor.bg.ignoresSafeArea())
    }
}

#if DEBUG
#Preview { AddTodoItemPlaceholderView {} }
#endif
