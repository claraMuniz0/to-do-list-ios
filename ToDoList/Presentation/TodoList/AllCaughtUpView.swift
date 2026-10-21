import SwiftUI

/// Shown in place of the sections when every task is completed. The copy comes from the view model.
struct AllCaughtUpView: View {
    let message: String
    let viewCompletedTitle: String
    let onViewCompleted: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            EmptyStateIllustration(symbol: "party.popper", layout: .celebration)
            Text("All caught up!")
                .dsFont(.emptyTitle)
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .dsFont(.inputText)
                .foregroundStyle(DSColor.textSecondary)
                .frame(maxWidth: 280)
            SoftPillButton(title: viewCompletedTitle, action: onViewCompleted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}

#if DEBUG
#Preview("All caught up") {
    AllCaughtUpView(message: "You finished 4 of 4 tasks. Enjoy the break!", viewCompletedTitle: "View completed (4)") {}
}
#Preview("Accessibility3") {
    ScrollView {
        AllCaughtUpView(message: "You finished 4 of 4 tasks. Enjoy the break!", viewCompletedTitle: "View completed (4)") {}
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
