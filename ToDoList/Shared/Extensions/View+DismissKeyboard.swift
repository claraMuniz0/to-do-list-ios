import SwiftUI

extension UIApplication {
    /// Closes the keyboard no matter which field has focus, including fields whose
    /// `@FocusState` is private to a design-system component (the description text area).
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
}
