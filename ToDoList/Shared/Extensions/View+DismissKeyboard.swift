import SwiftUI

extension View {
    /// Closes the keyboard on tap no matter which field has focus, including fields whose
    /// `@FocusState` is private to a design-system component (the description text area).
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }
    }
}
