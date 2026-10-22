import SwiftUI

enum CircularIconButtonMetrics {
    /// Visual size and hit area: the design's 44pt circle.
    static let diameter: CGFloat = DSTouchTarget.minimum
    static let iconSize: CGFloat = 20
}

/// The circle itself (surface fill, border, centered icon), usable as a `Menu` label where a `Button` cannot wrap it.
struct CircularIconButtonLabel: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: CircularIconButtonMetrics.iconSize, weight: .regular))
            .foregroundStyle(DSColor.textPrimary)
            .frame(width: CircularIconButtonMetrics.diameter, height: CircularIconButtonMetrics.diameter)
            .background(DSColor.surface, in: Circle())
            .overlay(Circle().stroke(DSColor.border, lineWidth: 1))
            .contentShape(Circle())
    }
}

/// Circular 44pt icon button for the list header (Search). `accessibilityLabel` is required: there is no text.
struct CircularIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var accessibilityHint: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CircularIconButtonLabel(systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

#if DEBUG
#Preview("Search") {
    CircularIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search") {}.padding()
}
#Preview("Sort") {
    CircularIconButtonLabel(systemImage: "arrow.up.arrow.down").padding()
}
#Preview("Pair") {
    HStack(spacing: 8) {
        CircularIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search") {}
        CircularIconButtonLabel(systemImage: "arrow.up.arrow.down")
    }
    .padding()
}
#endif
