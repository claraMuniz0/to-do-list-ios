import SwiftUI

/// Stand-in until the Add Task form lands in Phase 3.
struct AddTodoItemPlaceholderView: View {
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            ScreenHeader(subtitle: "What's on your mind?", title: "New task")
                .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Close", fullWidth: true, action: onClose)
                .padding(20)
                .background(DSColor.bg)
        }
        .background(DSColor.bg.ignoresSafeArea())
        .accessibilityAction(.escape, onClose)
    }
}

#if DEBUG
#Preview { AddTodoItemPlaceholderView {} }
#Preview("Accessibility3") { AddTodoItemPlaceholderView {}.dynamicTypeSize(.accessibility3) }
#endif
