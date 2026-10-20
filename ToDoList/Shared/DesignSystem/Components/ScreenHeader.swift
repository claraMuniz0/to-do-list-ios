import SwiftUI

/// Caveat accent subtitle above an italic Fraunces title. Shared by Welcome, Add Task and Task List.
struct ScreenHeader: View {
    let subtitle: String
    let title: String

    init(subtitle: String, title: String) {
        self.subtitle = subtitle
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle)
                .dsFont(.greeting)
                .foregroundStyle(DSColor.accent)
            Text(title)
                .dsFont(.screenTitle)
                .foregroundStyle(DSColor.accent)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Welcome") { ScreenHeader(subtitle: "Welcome 👋", title: "My Tasks").padding() }
#Preview("Add task") { ScreenHeader(subtitle: "What's on your mind?", title: "New task").padding() }
#Preview("Long text") {
    ScreenHeader(subtitle: "You have a lot of tasks left today", title: "My very busy Tasks").padding()
}
#Preview("Accessibility3") {
    ScreenHeader(subtitle: "3 tasks left today", title: "My Tasks").padding().dynamicTypeSize(.accessibility3)
}
#endif
